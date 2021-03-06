% MAIN_MESHREFINEMENT - Main script to solve the Optimal Control Problem
% with mesh refinement
%
% Copyright (C) 2018 Yuanbo Nie, Omar Faqir, and Eric Kerrigan. All Rights Reserved.
% The contribution of Paola Falugi, Eric Kerrigan and Eugene van Wyk for the work on ICLOCS Version 1 (2010) is kindly acknowledged.
% This code is published under the BSD License.
% Department of Aeronautics and Department of Electrical and Electronic Engineering,
% Imperial College London London  England, UK 
% ICLOCS (Imperial College London Optimal Control) Version 2.0 
% 1 May 2018
% iclocs@imperial.ac.uk


%--------------------------------------------------------

clear all;close all;format compact;

global sol;  
sol=[];                             % Initialize solution structure

[problem,guess]=myProblem;  		% Fetch the problem definition


%%%% Choice among the ones belwo %%%%
% options= settings_auto(40);                  
% options= settings_h(40);                
% options= settings_hp(5,4);                 
options= settings_hp([4 5 3],[-1 0.3 0.4 1]);    % Get options and solver settings   

% Declare variables for storage
errorHistory=zeros(2,length(problem.states.x0));
npsegmentHistory=zeros(2,1);
ConstraintErrorHistory=zeros(2,length(problem.constraintErrorTol));
timeHistory=zeros(1,2);
iterHistory=zeros(1,2);
solutionHistory=cell(1,2);

maxAbsError=1e9; % the initial (before start) maximum absolute local eeror
i=1; % starting iteration
imax=50; % maximum number of mesh refinement iterations

%% without external constraint handling, comment as needed
while (any(maxAbsError>problem.states.xErrorTol) || any(maxAbsConstraintError>problem.constraintErrorTol)) && i<=imax  
    [infoNLP,data,options]=transcribeOCP(problem,guess,options); % Format for NLP solver
    [solution,status,data] = solveNLP(infoNLP,data);      % Solve the NLP
    [solution]=output(problem,solution,options,data,4);         % Output solutions
    
    maxAbsError=max(abs(solution.Error));
    maxAbsConstraintError=max(solution.ConstraintError);
    errorHistory(i,:)=maxAbsError;
    iterHistory(i)=status.iter;
    ConstraintErrorHistory(i,:)=maxAbsConstraintError;
    timeHistory(i)=solution.computation_time;
    solutionHistory{i}=solution;
    
    if (any(maxAbsError>problem.states.xErrorTol) || any(maxAbsConstraintError>problem.constraintErrorTol)) && i<=imax
        [ options, guess ] = doMeshRefinement( options, problem, guess, data, solution, i );
    end
    i=i+1;
end

%% with external constraint handling, uncomment as needed
% problem_iter=problem;
% while (any(maxAbsError>problem.states.xErrorTol) || any(maxAbsConstraintError>problem.constraintErrorTol)) && i<=imax
%     if i~=1
%         [ problem_iter,guess,options ] = selectAppliedConstraint( problem, guess, options, data, solutionHistory, i );
%     end
%     [infoNLP,data,options]=transcribeOCP(problem_iter,guess,options); % Format for NLP solver
%     [solution,status,data] = solveNLP(infoNLP,data);      % Solve the NLP
%     [solution]=output(problem,solution,options,data,4);         % Output solutions
% 
%     
%     maxAbsError=max(abs(solution.Error));
%     maxAbsConstraintError=max(solution.ConstraintError);
%     errorHistory(i,:)=maxAbsError;
%     iterHistory(i)=status.iter;
%     ConstraintErrorHistory(i,:)=maxAbsConstraintError;
%     timeHistory(i)=solution.computation_time;
%     solutionHistory{i}=solution;
% 
%     if (any(maxAbsError>problem.states.xErrorTol) || any(maxAbsConstraintError>problem.constraintErrorTol)) && i<=imax
%         [ options, guess ] = doMeshRefinement( options, problem, guess, data, solution, i );
%     end
%     i=i+1;
% end

%%
MeshRefinementHistory.errorHistory=errorHistory;
MeshRefinementHistory.timeHistory=timeHistory;
MeshRefinementHistory.iterHistory=iterHistory;
MeshRefinementHistory.ConstraintErrorHistory=ConstraintErrorHistory;

