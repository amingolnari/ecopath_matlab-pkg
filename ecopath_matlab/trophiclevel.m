function level = trophiclevel(dc, pp, nlive, ngroup)
%TROPHICLEVEL Estimates trophic level of food web members
%
% level = trophiclevel(dc, pp, nlive, ngroup)
% level = trophiclevel(A)
% level = trophiclevel(EM)
%
% This function calculates the trophic levels of each member of a food web,
% based on their diets and whether they are primary producers/detrital.
% The calculations derive from EstimateTrophicLevels in the EwE model.
% Primary producers and detrital groups receive a trophic level of 1, while
% consumers are assigned 1 + w, where w is the weighted average of their
% prey's trophic levels.
%
% Input variables:
%
%   dc:     ngroup x ngroup array, diet composition, dc(i,j) tells fraction
%           of predator j's diet consisting of prey i  
%
%   pp:     ngroup x 1 array, 1 = is primary producer, 0 = is not primary
%           producer, 2 = is detrital
%
%   nlive:  scalar, number of live, non-detrital groups
%
%   ngroup: scalar, number of functional groups in model
%
%   A:      structure with fields corresponding to the above 4 variables
%           (e.g., an ecopathlite input structure)
%
%   EM:     ecopathmodel object
%
% Output variables:
%
%   level:  ngroup x 1 array, trophic levels of each functional group

% Copyright 2007-2016 Kelly Kearney

if nargin == 1
    if isa(dc, 'ecopathmodel')
        A = dc;
        dc = table2array(A.dc);
        pp = A.groupdata.pp;
        nlive = A.nlive;
        ngroup = A.ngroup;
    elseif isa(dc, 'struct')
        A = dc;
        dc = A.dc;
        pp = A.pp;
        nlive = A.nlive;
        ngroup = A.ngroup;
    end
end

% Sort based on pp

[pp, isrt] = sort(pp);
dc = dc(isrt,isrt);

%--------------------------
% Set up set of left-hand 
% side based on type of 
% feeder (producer, 
% consumer, or detritus)
% and diet composition
%--------------------------

dc = dc';

tl = ones(ngroup,1);
lhs = zeros(size(dc));

sumdc = sum(dc,2);

pp = repmat(pp, 1, ngroup);
sumdc = repmat(sumdc, 1, ngroup);

% Strict primary producer

lhs(pp == 1) = 0;

% Partial primary producer

lhs(pp > 0) = -dc(pp > 0);

% Consumers with import (TODO: How does this situation arise?  It doesn't
% seem possible to balance an ecopath model when the dc values do not all
% sum to 1)

temp = pp <= 0 & abs(sumdc - 1) > .0001;
lhs(temp) = -dc(temp) ./ sumdc(temp);

% Strict consumers

temp = pp <= 0 & abs(sumdc - 1) <= .0001;
lhs(temp) = -dc(temp);

% Mixed primary producer/consumer

temp = pp > 0 & pp < 1;
lhs(temp) = -dc(temp) .* (1 - pp(temp));

% Self-predation

isdiag = logical(eye(ngroup));
lhs(isdiag) = 1 - dc(isdiag);

% Detritus

isdet = false(size(dc));
isdet(nlive+1:ngroup,:) = true;

lhs(isdet) = 0;
lhs(isdet & isdiag) = 1;

%--------------------------
% Least-squares solution
%--------------------------

level = lhs\tl;
level(isrt) = level; % sort back to input order

