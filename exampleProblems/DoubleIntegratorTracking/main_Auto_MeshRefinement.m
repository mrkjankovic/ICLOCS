% main_Auto_MeshRefinement - Main script to solve the Optimal Control Problem with automatic mesh selection and refinement
%
% Double Integrator Tracking Problem
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

options= settings_Auto(40);                  % Get options and solver settings 
[problem,guess]=DoubleIntergratorTracking;          % Fetch the problem definition
errorHistory=zeros(2,length(problem.states.x0));
npsegmentHistory=zeros(2,1);
ConstraintErrorHistory=zeros(2,length(problem.constraintErrorTol));
timeHistory=zeros(1,2);
solutionHistory=cell(1,2);

maxAbsError=1e9;
i=1; imax=50;

while (any(maxAbsError>problem.states.xErrorTol) || any(maxAbsConstraintError>problem.constraintErrorTol)) && i<=imax    
    [infoNLP,data,options]=transcribeOCP(problem,guess,options); % Format for NLP solver
    [solution,infoNLP1,data] = solveNLP(infoNLP,data);      % Solve the NLP
    [solution]=output(problem,solution,options,data,4);         % Output solutions
    
    
    maxAbsError=max(abs(solution.Error));
    maxAbsConstraintError=max(solution.ConstraintError);
    errorHistory(i,:)=maxAbsError;
    ConstraintErrorHistory(i,:)=maxAbsConstraintError;
    timeHistory(i)=solution.computation_time;
    solutionHistory{i}=solution;
    
    if (any(maxAbsError>problem.states.xErrorTol) || any(maxAbsConstraintError>problem.constraintErrorTol)) && i<=imax
        [ options, guess ] = doMeshRefinement( options, problem, guess, data, solution, i );
    end
    i=i+1;

end

MeshRefinementHistory.errorHistory=errorHistory;
MeshRefinementHistory.timeHistory=timeHistory;
MeshRefinementHistory.ConstraintErrorHistory=ConstraintErrorHistory;


%%
xx=linspace(solution.T(1,1),solution.tf,1000);

if (strcmp(options.transcription,'globalLGR')) || (strcmp(options.transcription,'hpLGR'))
     figure
    plot([solution.T(:,1); solution.tf],speval(solution.Xp,1,solution.TSeg_Bar,[solution.T(:,1); solution.tf]),'ro' )
    hold on
    plot([solution.T(:,1); solution.tf],speval(solution.Xp,2,solution.TSeg_Bar,[solution.T(:,1); solution.tf]),'bd' )
    plot(xx,speval(solution.Xp,1,solution.TSeg_Bar,xx),'r-' )
    plot(xx,speval(solution.Xp,2,solution.TSeg_Bar,xx),'b-.' )
    xlabel('Time [s]')
    ylabel('States')
    legend('Position [m]','Velocity [m/s]')
    grid on

    figure
    plot([solution.T(:,1); solution.tf],speval(solution.Up,1,solution.TSeg_Bar,[solution.T(:,1); solution.tf]),'bo' )
    hold on
    plot(xx,speval(solution.Up,1,solution.TSeg_Bar,xx),'b-' )
    plot([solution.T(1,1); solution.tf],[problem.inputs.ul, problem.inputs.ul],'r-' )
    plot([solution.T(1,1); solution.tf],[problem.inputs.uu, problem.inputs.uu],'r-' )
    xlabel('Time [s]')
    grid on
    ylabel('Control Input')
    legend('u [N]')

    figure
    plot([solution.T(:,1); solution.tf],abs(speval(solution.Xp,1,solution.TSeg_Bar,[solution.T(:,1); solution.tf])-5.*sin([solution.T(:,1); solution.tf])),'-o' )
    xlabel('Time [s]')
    grid on
    ylabel('Tracking error [m]')
    legend('Position error')
    

else
    figure
    plot(solution.T(:,1),speval(solution.Xp,1,solution.T(:,1)),'ro-' )
    hold on
    plot(solution.T(:,1),speval(solution.Xp,2,solution.T(:,1)),'bd-.' )
    xlabel('Time [s]')
    ylabel('States')
    legend('Position [m]','Velocity [m/s]')
    grid on

    figure
    plot(solution.T(:,1),speval(solution.Up,1,solution.T),'bo-' )
    hold on
    plot([solution.T(1,1); solution.tf],[problem.inputs.ul, problem.inputs.ul],'r-' )
    plot([solution.T(1,1); solution.tf],[problem.inputs.uu, problem.inputs.uu],'r-' )
    hold on
    xlabel('Time [s]')
    grid on
    ylabel('Control Input')
    legend('u [N]')

    figure
    plot(solution.T(:,1),(speval(solution.Xp,1,solution.T(:,1))-5.*sin(solution.T(:,1))),'-o' )
    xlabel('Time [s]')
    grid on
    ylabel('Tracking error')
    legend('Position error [m]')
end