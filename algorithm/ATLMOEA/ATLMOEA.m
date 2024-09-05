classdef ATLMOEA < ALGORITHM
% <multi/many> <real> <large/none> <constrained/none>
% An Adaptive Two-Stage Evolutionary Large-scale multi-objective optimization algorithm

%------------------------------- Reference --------------------------------
% Q. Lin, J. Li, S. Liu, et al., An Adaptive Two-Stage Evolutionary
% Algorithm for Large-Scale Continuous Multi-Objective Optimization, Swarm and
% Evolutionary Computation, 2023.
%------------------------------- Copyright --------------------------------
% Copyright (c) 2021 BIMK Group. You are free to use the PlatEMO for
% research purposes. All publications which use this platform or any code
% in the platform should acknowledge the use of "PlatEMO" and reference "Ye
% Tian, Ran Cheng, Xingyi Zhang, and Yaochu Jin, PlatEMO: A MATLAB platform
% for evolutionary multi-objective optimization [educational forum], IEEE
% Computational Intelligence Magazine, 2017, 12(4): 73-87".
%--------------------------------------------------------------------------

    methods
        function main(Algorithm,Problem)
            %% Generate random population
            [V,Problem.N] = UniformPoint(Problem.N,Problem.M);
            Population    = Problem.Initialization();
            flag = false;
            [z,znad]      = deal(min(Population.objs),max(Population.objs));
            %% Optimization
            while Algorithm.NotTerminated(Population)
                while flag ==false
                    eNum = 0;
                   [P,LabelSet]= classification(Population);
                    t = (Problem.FE/Problem.maxFE);
                    Lx=training(P,LabelSet,Problem,Population);
                    for i = 1:Problem.N
                        if rand <0.5
                                P1 = randperm(Problem.N,1);
                                P2 = randperm(Problem.N,1);
                                Offspring1(1,i) = OperatorDE1(Problem,Population(i),Population(P1),Population(P2),Lx(i,:),t);
                         else
                                P1 = randperm(Problem.N,1);
                                P2 = randperm(Problem.N,1);
                                Offspring1(1,i) =OperatorDE(Problem,Population(i),Population(P1),Population(P2));
                         end
                    end
                    Offspring = Offspring1;
                    for i = 1: Problem.N
                        Population1 = [Offspring Population(1,i)];
                        [FrontNo,MaxFNo] = NDSort(Population1.objs,Population1.cons,Problem.N+1);
                        if FrontNo(end)~=1
                                eNum = eNum+1;
                        end
                    end 
                    eNum1 = eNum/Problem.N;
                    if eNum1 <0.1
                        flag = true;
                    end
                     [Population,FrontNo,CrowdDis] = EnvironmentalSelection1([Population,Offspring],Problem.N);   
                end
                 while size(Population,2)< 4
                    a = size(Population,2);
                    Population(1,a+1)=Population(1,randperm(size(Population,2),1));
                end
                Fitness = calFitness(Population.objs);
                [P1,P2,A,B] = classification1(Population,z,znad,V);
                [level1,level2,L1,L2] = classification1(P1,z,znad,V);
                [level3,level4,L3,L4] = classification1(P2,z,znad,V);
                Rank=randperm(length(Population),floor(length(Population)/2)*2);
                Loser  = Rank(1:end/2);
                Winner = Rank(end/2+1:end);
                a1=A(L1);
                a2=B(L3);
                b1=A(L2);
                b2=B(L4);
                loser = zeros(1,size(Loser,2));
                winner = zeros(1,size(Winner,2));
                for i = 1:length(Population)/4
                    loser(find(Loser==a1(i)))=1;
                    loser(find(Loser==b1(i)))=2;
                    loser(find(Loser==a2(i)))=3;
                    loser(find(Loser==b2(i)))=4;
                end
                for i = 1:length(Population)/4
                    winner(find(Winner==a1(i)))=1;
                    winner(find(Winner==b1(i)))=2;
                    winner(find(Winner==a2(i)))=3;
                    winner(find(Winner==b2(i)))=4;
                end
                Change = loser<winner;
                Exam = loser==winner;
                Change1 = [];
                for i=1:length(Exam)
                    if(Exam(i)==true&&(Fitness(Loser(i)))>Fitness(Winner(i)))
                        Change1 = [Change1,i];
                    end
                end
                Change(Change1)=1;
                Temp   = Winner(Change);
                Winner(Change) = Loser(Change);
                Loser(Change)  = Temp;  
                Offspring      = Operator(Problem,Population(Loser),Population(Winner));
                Population     = EnvironmentalSelection([Population,Offspring],V,(Problem.FE/Problem.maxFE)^2);
                  end
            end
        end
 end


function Fitness = calFitness(PopObj)
% Calculate the fitness by shift-based density

    N      = size(PopObj,1);
    fmax   = max(PopObj,[],1);
    fmin   = min(PopObj,[],1);
    PopObj = (PopObj-repmat(fmin,N,1))./repmat(fmax-fmin,N,1);
    Dis    = inf(N);
    for i = 1 : N
        SPopObj = max(PopObj,repmat(PopObj(i,:),N,1));
        for j = [1:i-1,i+1:N]
            Dis(i,j) = norm(PopObj(i,:)-SPopObj(j,:));
        end
    end
    Fitness = min(Dis,[],2);
end
