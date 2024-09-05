function Lx=training(P,LabelSet,Problem,Population,t)
    [N,nL1] = size(P.decs);  
    nL2 = 10; 
    [~,nL3] = size(LabelSet.decs);
    trainNum =N ;
    trainData = P.decs;
    targetData = LabelSet.decs;
    trainData =P.decs-repmat(Problem.lower,N,1)./(repmat(Problem.upper,N,1)-repmat(Problem.lower,N,1));
    targetData =LabelSet.decs-repmat(Problem.lower,N,1)./(repmat(Problem.upper,N,1)-repmat(Problem.lower,N,1));
    V = unifrnd(0,1,nL1,nL2);  
    W = unifrnd(0,1,nL2,nL3); 
    doorL2 = unifrnd(0,1,nL2,1)'; 
    doorL3 = unifrnd(0,1,nL3,1)';  
    actL2 = [];  
    forecast = [];  
    eL3 = [];
    eL2 = []; 
    Alpha = 0.1; 
    Beta = 0.1;   
    Maxpoch = 1;
    for i = 1 : Maxpoch
        ek = 0;
        for k = 1 : trainNum
            actL2 = extractdata(sigmoid(dlarray(trainData(k,:) * V+doorL2)));
            forecast = extractdata(sigmoid(dlarray(actL2 * W+doorL3)));
            ek = ek + sum((targetData(k,:)-forecast).^2,2)/2;
            eL3 = forecast.*(1-forecast).*(targetData(k,:)-forecast);
            eL2 = actL2.*(1-actL2).*(eL3*W');
            W = W + actL2'*eL3*Alpha;
            V= V + trainData(k,:)'*eL2*Beta;
            doorL2 = doorL2 + eL2*Beta;
            doorL3 = doorL3 + eL3*Alpha;     
        end
        ek = ek / trainNum; 
    end
    [n,~] = size(Population.objs);
    predictData = Population.decs-repmat(Problem.lower,n,1)./(repmat(Problem.upper,n,1)-repmat(Problem.lower,n,1));
    for k = 1: n
        actL2 = extractdata(sigmoid(dlarray(predictData(k,:) * V+doorL2)));
        forecast = extractdata(sigmoid(dlarray(actL2 * W+doorL3)));
        h = forecast.*(Problem.upper-Problem.lower)+Problem.lower;
        h1 = Population(k).decs;
        Site = rand(1,nL1) <1;
        Site1 = ~Site;
        Lx1(Site) = h(Site);
        Lx1(Site1) = h1(Site1);
        Lx(k,:) = Lx1;
    end
 end
  






