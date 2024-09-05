function [P,LabelSet] = classification(Population)

  [N,M] = size(Population.objs);
  [FrontNo,MaxFNo] = NDSort(Population.objs,Population.cons,N);
  front = unique(FrontNo)';
  next = zeros(1,N);
  next0 = find(FrontNo<MaxFNo);
  if(sum(next0)==0)
    next0 =  find(FrontNo==MaxFNo);
  end
  next(next0) = true;
  p = Population(logical(next')).objs;
  remain =N-fix(N/2);
  i = 1;
  q = sum(FrontNo==front(i));
  s = [remain>0,remain>=q];
  Next = zeros(1,N);
  Next1 = zeros(1,N);
  while sum(s)==2
    Next0 = find(FrontNo==front(i));
    Next(Next0) = true;
    remain =remain -sum(FrontNo==front(i));
    i = i+1;
    q = sum(FrontNo==front(i));
    s = [remain >0,remain >=q];
  end
  if(remain >0)
    CrowdDis = CrowdingDistance(Population.objs,FrontNo);
    Last = find(FrontNo==front(i));
    [~,Rank] = sort(CrowdDis(Last),'descend');
    Next(Last(Rank(1:remain))) = true;
    Next1(Last(Rank(remain+1:q))) = true;
  end
  i = i+1;
  Next1(find(Next==0))=true;
  E = Population(logical(Next'));
  P =Population(logical(Next1'));
   LabelSet = getLabel1(E,P);
end

function LabelSet = getLabel1(E,P)
  P1 = P.objs;
  E1 = E.objs;
  [N1,M1] = size(P1);
  [N2,~] = size(E1);
  for i = 1:N1
     rad(i) = randperm(N2,1);     
  end
  LabelSet = E(rad(i));
end
  
 function dis=distance(p,E1)
  [N2,~] = size(E1);
  sum1 = sum(p);
  v1 = p/sum1;
  dis = zeros(1,N2);
  for j= 1:N2
     e = E1(j,:);
     sum2 = sum(e);
     v2 = e/sum2;
     dis(j) = sum((v1-v2).^2);
  end
  end
 
  
  