% Run this function to find dendrite shift and to perform nucleus search
%
% Standard Operating Procedure
%
%   If you just opened matlab, your matlab search path not be correct
%       In the Command Window, use:
%           matlabpath(pathdef)
%       The Current Folder will need to be set to where ever pathdef.m is
%
%   Load spc_main by entering in the Command Window
%       spc_drawInit
%
%   Find a good starting image, with spc_main, for each cycle
%
%   Edit this file to say which cycle is
%       Dendrite = 0
%       Nucleus search = 1
%   For dendrite shift,
%       Manually select ROI
%   For nucleus search,
%       Edit this file to specify which channel is to be inverted
%
%   Now you can run this function


% Fix Figure Offset
global offset fixoffset
fixoffset=1;
offset=spc.switchess{1}.figOffset;

%% Cycle Identification and Nucleus Color Input
% Specify current image number, then 0 for dendrite or COLOR for nucleus
% where COLOR is the color of the nucleus
%   Use format:
%       CycleIdentification = {numImg1 type; numImg2 type; numImg3 type};
%
%   example:
%       CycleIdentification = {63 0; 65 0; 62 'red'}
%
%           Image #63 is dendrite
%           Image #65 is dendrite
%           Image #62 is nucleus, nucleus color is red




% CycleIdentification = {26 'blue'};        % Set 692
% CycleIdentification = {28 'blue'};        % Set 692   multiple cells
% CycleIdentification = {78 'blue'};        % Set 695   multiple cells, close together
% CycleIdentification = {80 'red'};         % Set 695   multiple cells
% CycleIdentification = {78 'blue';80 'red'}; % Set 695
% CycleIdentification = {62 'blue'}; % Set 696
% CycleIdentification = {97 'blue'}; % Set 697, multiple cells
% CycleIdentification = {55 'red/blue'}; % Set 697
% CycleIdentification = {43 'red'}; % Set 700
% CycleIdentification = {24 'blue'}; % Set 705
% CycleIdentification = {58 'blue'}; % Set 705, multiple cells
% CycleIdentification = {53 'blue'}; % Set 706
% CycleIdentification = {53 'blue'}; % Set 711, nucleus + dendrites
% CycleIdentification = {52 'blue'}; % Set 711
% CycleIdentification = {62 'red'}; % Set 717
% CycleIdentification = {64 'red/blue'}; % Set 717
% CycleIdentification = {73 'blue'}; % Set 729 % Multiple cells, large connected
% CycleIdentification = {24 'blue'}; % Set 730 % Multiple cells, large connected
% CycleIdentification = {'blue'}; % Set 730 % Multiple cells, in/out near boundary
% CycleIdentification = {26 'blue'}; % Set 731 % Multiple cells + dendrites, close together
% CycleIdentification = {63 'blue'}; % Set 734
% CycleIdentification = {61 'blue'}; % Set 734 % Multiple cells, in/out
% CycleIdentification = {11 'red'; 12 0; 13 0}; % Set 687 % two joint cells
% CycleIdentification = {20 0}; % Set 209 branching dendrites



% CycleIdentification = {16 'blue'}; % Set 666, multiple cells



% CycleIdentification = {26 'blue'; 28 'blue'}; % Set 692



% CycleIdentification = {76 'blue'; 74 'blue'}; % Set 664



% CycleIdentification = {79 0}; % Dendrite
% CycleIdentification = {111 'blue'}; % Set 706
% CycleIdentification = {11 'blue'; 12 0; 13 'blue'}; % Set 664; multiple cells with appendages for 13
% CycleIdentification = {16 'blue'; 17 0; 18 'blue'; 19 'blue'}; % Set 662; multiple/connected cells
% CycleIdentification = {17 0}; % Set 662; dendrite
% CycleIdentification = {18 'blue'}; % Set 662; single cell
% CycleIdentification = {19 'blue'}; % Set 662; 2 small cells, with appendages.
% CycleIdentification = {16 'blue'}; % Set 662; multiple connected cells, crashed the code
% CycleIdentification = {16 0; 17 'blue';18 0; 19 'blue' }; % Set 669; multiple cells.
% CycleIdentification = {13 0; 14 'blue';15 0; 16 'blue' }; % Set 663; multiple cells.
% CycleIdentification = {13 0; 15 0 }; % Set 663; dendrites.
% CycleIdentification = {16 'blue'}; % Set 663; single cell.
% CycleIdentification = {14 'blue'}; % Set 663; multiple cells.



% CycleIdentification = {24 'blue';26 'blue'}; % Set 728
% CycleIdentification = {23 'blue';24 0; 25 'blue'; 26 0}; % Set 494
% CycleIdentification = {26 'blue';27 'blue'; 28 0; 29 0}; % Set 495
% CycleIdentification = {26 'blue';27 'blue'; 28 'blue'}; % Set 493, connected multiple soma.
% CycleIdentification = {28 'blue'}; % Set 493, connected multiple soma.
% CycleIdentification = {42 'blue';43 'blue'; 44 0}; % Set 626.
% CycleIdentification = {12 'blue';13 'blue'; 14 0}; % Set 625.
% CycleIdentification = {19 'blue';20 0;21 'blue' }; % Set 627.
% CycleIdentification = {19 'blue';20 'blue'; }; % Set 628.




% CycleIdentification = {26 'blue';27 'blue'; 28 0; 29 0; 30 'blue'; 31 'blue'}; % Set 495
% CycleIdentification = {35 0;36 'blue';37 'blue'};        % Set 711   multiple cells
% CycleIdentification = {20 'blue'; 21 0;22 'blue';23 0  };        % Set 692
% CycleIdentification = {82 0}; % Set 691
% CycleIdentification = {8 0; 9 0; 10 0}; % Set 784 all dendrites
% CycleIdentification = {12 'blue'; 13 0}; % Set 789
% CycleIdentification = {3 'red'; 4 0}; % Set 785
% CycleIdentification = {17 'blue'}; % Set 786 soma only
% CycleIdentification = {16 'blue'; 17 'blue'; 18 0}; % Set 790 
% CycleIdentification = {6 'blue'; 7 0}; % Set 791
% CycleIdentification = {19 'blue'; 20 0}; % Set 816
% CycleIdentification = {16 'blue'; 17 0}; % Set 817
% CycleIdentification = {7 0}; % Set 818
% CycleIdentification = {18 0; 19 'blue'; 20 0}; % Set 819
%  CycleIdentification = {17 'blue'}; % Set 819 2 cells (had trouble with
%  photon threshold)
%  CycleIdentification = {16 'blue'; 17 0; 19 0 }; % Set 820
%  CycleIdentification = {22 'blue'}; % Set 820
% CycleIdentification = {36 'blue'; 37 'blue'; 38 0; 39 'blue' }; % Set 596
% CycleIdentification = {28 'blue'; 29 0; 30 'blue'; 31 0 }; % Set 595
% CycleIdentification = {29 'red'; 30 0; 32 0 }; % Set 593
% CycleIdentification = {30 'blue'; 31 0; 32 'blue'; 33 0 }; % Set 592
% CycleIdentification = {29 'blue'; 30 'blue'; 31 'blue'; 32 0 }; % Set 591
% CycleIdentification = {30 'blue'; 31 0; 32 'blue'; 33 'blue' }; % Set 590
% CycleIdentification = {28 'blue'; 29 'blue'; 30 'blue'; 31 'blue'}; % Set 589
% CycleIdentification = {28 0; 29 'blue'; 30 'blue'; 31 'blue'}; % Set 588
% CycleIdentification = {28 'blue'; 29 0; 30 'red'; 31 0}; % Set 587
% CycleIdentification = {28 'blue'; 29 0; 30 'blue'; 31 0}; % Set 586
% CycleIdentification = {27 'blue'; 28 0; 29 'blue'; 30 0}; % Set 585
% CycleIdentification = {7 'blue'; 8 0}; % Set 439
% CycleIdentification = {13 0}; % Set 440
% CycleIdentification = {12 'blue'}; % Set 440 - need to adjust photon threshold
% CycleIdentification = {24 'blue'}; % Set 441
% CycleIdentification = {11 'blue'; 12 'blue'; 13 0}; % Set 496
% CycleIdentification = {20 'blue'; 21 0}; % Set 448
% CycleIdentification = {20 'blue'; 21 'blue';22 0;23 'blue'  }; % Set 504
% CycleIdentification = {19 'blue'; 21 'blue';20 0; 22 0;}; % Set 506
% CycleIdentification = {6 'blue'; 7 0; 8 'blue' }; % Set 507
% CycleIdentification = {8 0; 9 'blue'; 10 0 }; % Set 508
% CycleIdentification = {7 'blue' }; % Set 508
% CycleIdentification = {7 'blue' }; % Set 509
% CycleIdentification = {9 'blue' }; % Set 508
% CycleIdentification = {13 0}; % Set 413 dendrite
% CycleIdentification = {12 'blue'}; % Set 413 soma
% CycleIdentification = {9 'blue'; 10 0}; % Set 414 
% CycleIdentification = {11 'blue'; 12 0}; % Set 415 
% CycleIdentification = {16 'red'; 17 0}; % Set 426 
% CycleIdentification = {18 'blue'; 19 'blue'}; % Set 428
% CycleIdentification = {15 'blue'; 16 0}; % Set 429
% CycleIdentification = {25 0}; % Set 433
% CycleIdentification = {24 'red'}; % Set 433, did not work.
% CycleIdentification = {11 'blue'; 12 0;13 'blue'; 14 0}; % Set 778
% CycleIdentification = {10 'blue'; 11 0;}; % Set 779
% CycleIdentification = {14 'blue'}; % Set 780, p1
% CycleIdentification = {15 'blue'}; % Set 780, p2
% CycleIdentification = {13 'blue'}; % Set 781,p4
% CycleIdentification = {20 'blue'; 21 0; 22 'blue'; 23 0}; % Set 782
% CycleIdentification = {10 'blue'; 11 'blue'; }; % Set 783
% CycleIdentification = {12 'blue'}; % Set 783
% CycleIdentification = {12 'blue'; 13 0; 14 'blue'; 15 0 }; % Set 823
% CycleIdentification = {8 0; 9 0; 10 0; 11 0 }; % Set 825
% % CycleIdentification = {12 'blue'; 13 0; 14 'blue'; 15 0 }; % Set 823
% CycleIdentification = {14 'blue' }; % Set 823
% CycleIdentification = {25 'blue' }; % Set 546
% CycleIdentification = {23 'blue'; 24 'blue'}; % Set 546
% CycleIdentification = {4 'blue'; 5 0 }; % Set 412
% CycleIdentification = {6 'blue'; 7 'blue'; 8 'blue' }; % Set 547
% CycleIdentification = {6 'blue'; 7 'blue'; }; % Set 548
% CycleIdentification = {8 'blue'; 9 'blue'; 10 0}; % Set 533
% CycleIdentification = {11 'blue'}; % Set 533
% CycleIdentification = {7 'blue'; 8 'blue'; 9 0; 10 'blue'}; % Set 532
% CycleIdentification = {5 'blue'; 6 0; 7 'blue'; 8 'blue'}; % Set 543
% CycleIdentification = {6 0; 7 'blue'; 8 'blue'}; % Set 534
% CycleIdentification = {5 'blue'}; % Set 534
% CycleIdentification = {6 'blue'}; % Set 535
% CycleIdentification = {5 'blue'; 8 0 }; % Set 535
% CycleIdentification = {7 'blue'}; % Set 535
%CycleIdentification = {15 'blue'; 16 'blue'}; % Set 555
% CycleIdentification = {9 'blue'}; % Set 535
%CycleIdentification = {7 'blue'}; % Set 549
%CycleIdentification = {17 'blue'}; % Set 555
%CycleIdentification = {9 'blue'; 10 'blue'; 11 'blue'; 12 'blue'; 13 'blue'}; % Set 556
%CycleIdentification = {8 'blue'}; % Set 557
%CycleIdentification = {9 'blue'; 10 'blue'; 11 'blue'; 12 'blue'; 13 'blue'}; % Set 556
%CycleIdentification = {8 'blue'; 9 'blue'; 10 'blue'; 11 'blue'; 12 'blue'}; % Set 557
%CycleIdentification = {6 'blue'; 7 'blue'; 8 'blue'; 9 'blue'; 10 'blue'}; % Set 558
%CycleIdentification = {3 'blue'}; % Set 560
%CycleIdentification = {131 'blue';132 'blue'; 133 'blue'}; % Set 560
%CycleIdentification = {108 'blue'}; % Set 561
%CycleIdentification = {3 'blue'}; % Set 564
%CycleIdentification = {5 'blue'; 6 'blue'; 7 'blue'}; % Set 578
%CycleIdentification = {140 'blue'; 141 'red'; 142 'blue'}; % Set 578
%CycleIdentification = {66 'blue'; 67 'blue'; 68 'blue'}; % Set 580
%CycleIdentification = {2 'blue'; 3 'blue'; 4 'blue'}; % Set 581
%CycleIdentification = {11 0; 12 'blue'; 13 0; 14 'blue'}; % Set 582
%CycleIdentification = {8 'blue'}; % Set 583
%CycleIdentification = {7 'red'; 8 'red'; 9 'blue'; 10 'blue'}; % Set 584
%CycleIdentification = {6 'blue'; 7 0; 8 'blue'} % Set 605
%CycleIdentification = {7 'blue'; 8 0; 9 'blue'; 10 'blue'} % Set 606
%CycleIdentification = {7 'red'; 8 0; 9 'blue'; 10 'blue'} % Set 606 
%CycleIdentification = {3 'blue'; 4 'blue'} % Set 607
%CycleIdentification = {7 'red'; 8 0; 9 'blue'; 10 'blue'} % Set 606
%CycleIdentification = {3 'blue'} % Set 216
%CycleIdentification = {9 'red'; 10 'red'; 11 'red'; 12 'red'; 13 'red'} % Set 556
%CycleIdentification = {8 'blue'; 9 'blue'; 10 'blue'; 11 'blue'; 12 'blue'} % Set 557
%CycleIdentification = {6 'blue'; 7 'blue'; 8 'blue'; 9 'blue'; 10 'blue'} % Set 558
%CycleIdentification = {3 'blue'} % Set 560
%CycleIdentification = {3 'blue'} % Set 561
%CycleIdentification = {5 'blue'; 6 'blue'; 7 'blue'} % Set 578
%CycleIdentification = {66 'blue'; 67 'blue'; 68 'blue'} % Set 580
%CycleIdentification = {7 'red'; 8 'red'; 9 'red'; 10 'red'} % Set 584
%CycleIdentification = {3 'blue'} % Set 883
%CycleIdentification = {5 'blue'; 6 'blue'; 7 'blue'} % Set 001
%CycleIdentification = {5 'blue'; 6 'blue'; 7 'blue'} % Set 001
%CycleIdentification = {6 'blue'; 7 'blue'; 8 0; 9 'blue'} % Set 002
%CycleIdentification = {6 'blue'; 7 'blue'; 8 'blue'; 9 0} % Set 887
%CycleIdentification = {5 'blue'; 6 0; 7 'blue'; 8 'blue'} % Set 888
%CycleIdentification = {6 'blue'; 7 0; 8 'blue'; 9 0} % Set 889
%CycleIdentification = {6 'blue'; 7 0; 8 'blue'; 9 'blue'} % Set 890
%CycleIdentification = {5 'blue'; 6 'blue'; 7 0; 8 'blue'} % Set 891
%CycleIdentification = {5 'blue'; 6 'blue'; 7 'blue'; 8 'blue'} % Set 892
%CycleIdentification = {7 'blue'; 8 'blue'} % Set 893
%CycleIdentification = {5 'blue'; 6 'blue'} % Set 894
%CycleIdentification = {5 'blue'; 6 'blue'; 7 'blue'; 8 'blue'} % Set 895
%CycleIdentification = {5 'blue'; 6 'blue'; 7 'blue'; 8 'blue'} % Set 896
%CycleIdentification = {6 'blue'; 7 'blue'; 8 0; 9 'blue'} % Set 002
%CycleIdentification = {6 'blue'; 7 'blue'; 8 0; 9 'blue'} % Set 002
%CycleIdentification = {6 'blue'; 7 'blue'; 8 0} % Set 002
%CycleIdentification = {6 'blue'; 7 'blue'; 8 0} % Set 002
%CycleIdentification = {9 'blue'} % Set 002
%CycleIdentification = {6 'blue'; 7 'blue'; 8 0; 9 'blue'} % Set 002
%CycleIdentification = {6 'blue'; 7 0; 8 'blue'} % Set 605
%CycleIdentification = {6 'blue'; 7 0; 8 'blue'} % Set 605
%CycleIdentification = {7 'blue'; 8 0; 9 'blue'; 10 'blue'} % Set 606
%CycleIdentification = {6 'blue'; 7 0; 8 'blue'} % Set 605
% CycleIdentification = {5 'blue'; 6 'blue'; 7 'blue'} % Set 578
%CycleIdentification = {6 'blue'; 7 'blue'; 8 0; 9 'blue'} % Set 002
%CycleIdentification = {6 'blue'; 7 0; 8 'blue' ; 9 'blue'} % Set 583
%CycleIdentification = {7 'blue'; 8 'blue' ; 9 0} % Set 249
% CycleIdentification = {5 'blue'; 6 'blue' ; 7 'blue'} % Set 251
%CycleIdentification = {8 'blue'; 9 0; 10 'blue'; 11 0} % Set 732
%CycleIdentification = {7 'blue'; 8 'blue'; 9 'blue'; 10 'blue'} % Set 902
%CycleIdentification = {6 'blue'; 7 'blue'; 8 'blue'; 9 'blue'} % Set 903
%CycleIdentification = {7 'blue'; 8 'blue'; 9 'blue'; 10 'blue'} % Set 905
%CycleIdentification = {4 'blue'; 5 'blue'; 6 'blue'} % Set 907
%CycleIdentification = {8 'blue'; 9 'blue'; 10 'blue'} % Set 908
%CycleIdentification = {7 'blue'; 8 'blue'; 9 'blue'; 10 'blue'} % Set 909
%CycleIdentification = {8 'blue'; 9 'blue'; 10 'blue'; 11 'blue'} % Set 910
%CycleIdentification = {9 'blue'; 10 'blue'; 11 'blue'; 12 'blue'} % Set 911
%CycleIdentification = {9 'blue'; 10 'blue'; 12 'blue'} % Set 911
%CycleIdentification = {5 'blue'; 6 'blue'; 7 'blue'; 8 'blue'} % Set 913
%CycleIdentification = {141 'red'} % Set 913
%CycleIdentification = {7 'red'} % Set 912
% CycleIdentification = {7 'blue'; 8 'blue'; 9 'blue'}; % Set 912
%CycleIdentification = {33 'blue'}; % Set 534
% CycleIdentification = {8 'red'}; % Set 583
%CycleIdentification = {9 'blue'}; % Set 584
% CycleIdentification = {8 'blue'}; % Set 584
% CycleIdentification = {6 'blue'}; % Set 605
%CycleIdentification = {8 'red'}; % Set 913
%CycleIdentification = {15 'blue'}; % Set 555
%CycleIdentification = {7 'blue'}; % Set 908
%CycleIdentification = {1 'blue'}; % Set 540
%CycleIdentification = {273 'blue'}; % Set 563
%CycleIdentification = {17 'blue'; 18 'blue'; 19 'blue'}; % Set 216
%CycleIdentification = {9 'blue'}; % Set 244
%CycleIdentification = {10 'blue'; 11 'blue'}; % Set 217
%CycleIdentification = {8 'blue'; 9 0; 10 'blue'}; % Set 245
%CycleIdentification = {8 'blue'; 9 0; 10 0}; % Set 246
%CycleIdentification = {4 'blue'}; % Set 279
%CycleIdentification = {9 'blue'; 10 0; 11 0; 12 'blue'}; % Set 921
%CycleIdentification = {5 'blue'; 6 'blue'; 7 'blue'}; % Set 922
%CycleIdentification = {4 'blue'; 5 'blue'; 6 'blue'}; % Set 944
%CycleIdentification = {22 'blue'; 23 'blue'; 24 0}; % Set 283
%CycleIdentification = {5 'blue'; 6 0; 7 'blue'; 8 'blue'}; % Set 310
%CycleIdentification = {1 'blue'; 2 'blue'; 3 'blue'; 4 'blue'}; % Set 954
%CycleIdentification = {6 'blue'; 7 0; 8 'blue'; 9 'blue'}; % Set 688
%CycleIdentification = {5 'blue'; 6 0; 7 'blue'; 8 0}; % Set 689
%CycleIdentification = {8 'blue'; 9 0; 10 'blue'; 11 0}; % Set 690
%CycleIdentification = {1 'blue'; 2 0; 3 'blue'; 4 0}; % Set 702
%CycleIdentification = {7 'blue'; 8 0; 9 'blue'; 10 0}; % Set 704
%CycleIdentification = {5 'blue'; 6 'blue'}; % Set 715
%CycleIdentification = {9 'blue'; 10 0; 11 'blue'}; % Set 716
%CycleIdentification = {8 'blue'; 9 0; 10 'blue'; 11 0}; % Set 717
%CycleIdentification = {6 'blue'; 7 0; 8 'blue'}; % Set 718
%CycleIdentification = {8 'blue'}; % Set 719
%CycleIdentification = {9 'blue'; 10 0; 11 'blue'; 12 0}; % Set 720
%CycleIdentification = {10 'blue'; 11 0; 12 'blue'; 13 0}; % Set 721
%CycleIdentification = {7 'blue'; 8 0; 9 'blue'; 10 0}; % Set 722
%CycleIdentification = {10 'blue'; 11 0; 12 'blue'; 13 0}; % Set 723
%CycleIdentification = {9 'blue'; 10 0; 11 'blue'; 12 0}; % Set 724
%CycleIdentification = {6 'blue'}; % Set 725
%CycleIdentification = {8 'blue'; 9 0; 10 'blue'; 11 0}; % Set 726
%CycleIdentification = {8 'blue'; 9 'blue'; 10 'blue'; 11 'blue'}; % Set 957
%CycleIdentification = {2 'blue'}; % Set 967
%CycleIdentification = {3 'blue'}; % Set 968
%CycleIdentification = {4 'blue'}; % Set 969
%CycleIdentification = {3 'blue'}; % Set 970
%CycleIdentification = {3 'blue'}; % Set 883
%CycleIdentification = {2 'blue'}; % pcAKAR019
% CycleIdentification = {2 'blue'}; % pcAKAR020
%CycleIdentification = {10 'red'; 11 'red'; 12 'red'}; % pcAKAR020
%CycleIdentification = {7 'red'}; % ycAKAR012 Wustl
%CycleIdentification = {125 'blue'}; % ycAKAR1185 Harvard
% CycleIdentification = {37 'blue'}; % ycAKAR014 Wustl
% CycleIdentification = {5 'blue';6 'blue'; 7 'blue'; 8 'blue'}; % ycAKAR004 Wustl
% CycleIdentification = {13 'blue';14 'blue'}; % test
% CycleIdentification = {11 0}; % ycAKAR032 Wustl; for position 2 use {11 0}
% CycleIdentification = {7 0}; % ycAKAR032 Wustl; for position 2 use {11 0}
% CycleIdentification = {5 0;6 0;7 0}; % 1127mAKARIUE002FLIM
% CycleIdentification = {9 'red'}; % ycAKAR061 Wustl
% CycleIdentification = {193 0}; % ycAKAR064 Wustl
% CycleIdentification = {193 0}; % ycAKAR065 Wustl
% CycleIdentification = {239 'blue'}; % ycAKAR036 Wustl
% CycleIdentification = {325 'red'}; % ycAKAR070 Wustl
% CycleIdentification = {51 'red'}; % ycAKAR071 Wustl
% CycleIdentification = {61 0}; % ycAKAR079 Wustl
% CycleIdentification = {678 0}; % ycAKAR079 Wustl
% CycleIdentification = {269 'red'}; % ycAKAR081 Wustl
% CycleIdentification = {10 'blue'}; % ycAKAR033 Wustl
% CycleIdentification = {9 0; 10 0; 11 0}; % JW FLIM-AKAR only FSK 
% CycleIdentification = {5 'blue'}; %ycAKAR095 Wustl
%CycleIdentification = {7 'blue'};
%CycleIdentification = {56 0;57 0;58 0}; %Peter 20210807_NO2
%CycleIdentification = {14 0;15 0;16 0}; %Peter 20210807_NO4
%CycleIdentification = {25 0;26 0;27 0}; %Peter 20210807_NO5
%CycleIdentification = {15 0;16 0;17 0}; %Peter 20210811.12_NO2
%CycleIdentification = {28 0;29 0;30 0}; %Peter 20210811.12_NO5
%CycleIdentification = {59 0;60 0;61 0}; %Peter 20210811.12_NO7
%CycleIdentification = {63 0;64 0;65 0}; %Peter 20210811.12_NO4
%CycleIdentification = {23 0;24 0;25 0}; %Peter 20210807_NO4
%CycleIdentification = {34 0;35 0;36 0}; %Peter 20210818_NO2
%CycleIdentification = {35 0;36 0;37 0}; %Peter 20210818_NO4
%CycleIdentification = {11 0;12 0;13 0}; %Peter 20210818_NO5
%CycleIdentification = {12 0;13 0;14 0}; %Peter 20210818_NO6
%CycleIdentification = {26 0;27 0;28 0}; %Peter 20210818_NO8
%CycleIdentification = {33 0;34 0;35 0}; %Peter 20211105_NO1
%CycleIdentification = {42 0;43 0;44 0}; %Peter 20211105_NO2
%CycleIdentification = {20 0;21 0;22 0}; %Peter 20211105_NO3
%CycleIdentification = {35 0;36 0;37 0}; %Peter 20211210_NO1
%CycleIdentification = {29 0;30 0;31 0}; %Peter 20211210_NO2
%CycleIdentification = {46 0;47 0;48 0}; %Peter 20211210_NO3
%CycleIdentification = {21 0;22 0;23 0}; %Peter 20211210_NO4
%CycleIdentification = {27 0;28 0;29 0}; %Peter 20220105_NO1
%CycleIdentification = {44 0;45 0;46 0}; %Peter 20220105_NO2
%CycleIdentification = {21 0;22 0;23 0}; %Peter 20220105_NO3
%CycleIdentification = {10 0;11 0;12 0}; %Peter 20220105_NO4
%CycleIdentification = {15 0;16 0;17 0}; %Peter 20220105_NO5
%CycleIdentification = {39 0;40 0;41 0}; %Peter 20220114_NO1
%CycleIdentification = {13 0;14 0;15 0}; %Peter 20220115_NO1
%CycleIdentification = {10 0;11 0;12 0}; %Peter 20220115_NO2
%CycleIdentification = {16 0;17 0;18 0}; %Peter 20220115_NO3
%leIdentification = {18 0;19 0;20 0}; %Peter 20220115_NO4
%CycleIdentification = {33 0;34 0;35 0}; %Peter 20220122_NO1
%CycleIdentification = {54 0;55 0;56 0}; %Peter 20220122_NO2
%CycleIdentification = {31 0;32 0;33 0}; %Peter 20220122_NO3
%CycleIdentification = {10 0;11 0;12 0}; %Peter 20220122_NO4
%CycleIdentification = {26 0;27 0;28 0}; %Peter 20220325_NO2
%CycleIdentification = {29 0;30 0;31 0}; %Peter 20220325_NO3
%CycleIdentification = {23 0;24 0;25 0}; %Peter 20220325_NO4
%CycleIdentification = {18 0;19 0;20 0}; %Peter 20220325_NO1
%CycleIdentification = {15 0;16 0;17 0}; %Peter 20220608_NO1
%CycleIdentification = {23 0;24 0;25 0}; %Peter 20220609_NO1
%CycleIdentification = {53 0;54 0;55 0}; %Peter 20220609_NO2
%CycleIdentification = {14 0;15 0;16 0}; %Peter 20220609_NO3
%CycleIdentification = {16 0;17 0;18 0}; %Peter 20220609_NO4
%CycleIdentification = {41 0;42 0;43 0}; %Peter 20220617_NO2
%CycleIdentification = {16 0;17 0;18 0}; %Peter 20220622_NO2
%CycleIdentification = {20 0;21 0;22 0}; %Peter 20220622_NO4
%CycleIdentification = {28 0;29 0;30 0}; %Peter 20220622_NO3

%CycleIdentification = {23 0;24 0;25 0}; %Peter 20220630_NO1
%CycleIdentification = {62 0;63 0;64 0}; %Peter 20220714_NO3
%CycleIdentification = {18 0;19 0;20 0}; %Peter 20220630_NO2
%CycleIdentification = {13 0;14 0;15 0}; %Peter 20220630_NO3
%CycleIdentification = {21 0;22 0;23 0}; %Peter 20220630_NO4
%CycleIdentification = {15 0;16 0;17 0}; %Peter 20220630_NO5
%CycleIdentification = {24 0;25 0;26 0}; %Peter 20220714_NO1
%CycleIdentification = {11 0;12 0;13 0}; %Peter 20220714_NO1
%CycleIdentification = {29 0;30 0;31 0}; %Peter 20220923_NO3
%CycleIdentification = {7 0}; % Active/Pingchuan/2022SPR/20220413_AchsensorHEK_001
%CycleIdentification = {16 0;17 0;18 0}; %Peter 20220923_NO3
%CycleIdentification = {2 0}; %Peter 20221020_NO2
%CycleIdentification = {8 0;9 0;10 0}; %Peter 20221021_NO5
%CycleIdentification = {9 0;10 0;11 0}; %Peter 20221021_NO2
%CycleIdentification = {9 0;10 0;11 0}; %Peter 20221020_NO1
%CycleIdentification = {16 0;17 0;18 0}; %Peter 20221103_NO1
%CycleIdentification = {35 0;36 0;37 0}; %Peter 20221103_NO2
%CycleIdentification = {22 0;24 0;26 0}; %Peter 20221104_NO2
%CycleIdentification = {23 0;24 0;25 0}; %Peter 20221104_NO1
%CycleIdentification = {51 0;53 0;55 0}; %Peter 20221110_NO1
% CycleIdentification = {21 0;22 0;23 0}; %Peter 20221117_NO1
%CycleIdentification = {24 0; 25 0; 26 0}; %Peter 20221117_NO2
%CycleIdentification = {29 0; 30 0; 31 0}; %Peter 20221117_NO3
% CycleIdentification = {3 0}; % /Volumes/yaochen/Active/Pingchuan/2023SPR/20230605_TMR_Temp_001
% CycleIdentification = {13 0; 14 0; 15 0}; % '/Users/pingchuanma/Desktop/ChenLab_Data/H2O2Sensor/20230702_H2O2_HEK_001/20230702_H2O2_HEK_001FLIM013.mat'
% CycleIdentification = {12 0; 13 0; 14 0}; % '/Users/pingchuanma/Desktop/ChenLab_Data/H2O2Sensor/20230702_H2O212_HEK_001/20230702_H2O212_HEK_001FLIM012.mat'
% CycleIdentification = {4 0};
% CycleIdentification = {112 0}; % '/Volumes/yaochen/Active/Pingchuan/2023Fall/20230816_AChSensor_Slice_001_dose_20X/20230816_AChSensor_Slice_001FLIM011.mat'
% CycleIdentification = {4 0}; % '/Volumes/yaochen/Active/Pingchuan/2023Fall/20230816_AChSensor_Slice_003_dose_20X/20230816_AChSensor_Slice_003FLIM004.mat'
% CycleIdentification = {5 0}; % '/Volumes/yaochen/Active/Pingchuan/2023Fall/20230817_AChSensor_Slice_001_dose_20X/20230817_AChSensor_Slice_001FLIM005.mat'
% CycleIdentification = {6 0}; % '/Volumes/yaochen/Active/Pingchuan/2023Fall/20230817_AChSensor_Slice_003_dose_20X/20230817_AChSensor_Slice_003FLIM006.mat'
% CycleIdentification = {12 0; 13 0}; % '/Volumes/yaochen/Active/Pingchuan/2023Fall/laser_power_slice_20X/20230814_AChSensor_Slice_002_LaserPower_20X/20230814_AChSensor_Slice_002FLIM009.mat'
% CycleIdentification = {15 0; 16 0}; % '/Volumes/yaochen/Active/Pingchuan/2023Fall/laser_power_slice_20X/20230814_AChSensor_Slice_003_LaserPower_20X/20230814_AChSensor_Slice_003FLIM015.mat'
% CycleIdentification = {11 0; 12 0}; % '/Volumes/yaochen/Active/Pingchuan/2023Fall/laser_power_slice_20X/20230815_AChSensor_Slice_003_LaserPower_20X/20230815_AChSensor_Slice_003FLIM011.mat'
% CycleIdentification = {7 0; 8 0}; % '/Volumes/yaochen/Active/Pingchuan/2023Fall/laser_power_slice_20X/20230816_AChSensor_Slice_002_LaserPower_20X/20230816_AChSensor_Slice_002FLIM007.mat'
% CycleIdentification = {10 0; 11 0}; % '/Volumes/yaochen/Active/Pingchuan/2023Fall/laser_power_slice_20X/20230816_AChSensor_Slice_004_LaserPower_20X/20230816_AChSensor_Slice_004FLIM010.mat'
% CycleIdentification = {7 0; 8 0}; % '/Volumes/yaochen/Active/Pingchuan/2023Fall/laser_power_slice_20X/20230817_AChSensor_Slice_002_LaserPower_20X/20230817_AChSensor_Slice_002FLIM007.mat'
% CycleIdentification = {7 0; 8 0}; % '/Volumes/yaochen/Active/Pingchuan/2023Fall/laser_power_slice_20X/20230817_AChSensor_Slice_004_LaserPower_20X/20230817_AChSensor_Slice_004FLIM007.mat'
% CycleIdentification = {19 0}; % '/Volumes/yaochen/Active/Pingchuan/2023Fall/puffing_SliceMode/20230820_AChSensor_Slice_002_puffing_60X/20230820_AChSensor_Slice_002FLIM019.mat'
% CycleIdentification = {87 0}; % '/Volumes/yaochen/Active/Pingchuan/2023Fall/puffing_SliceMode/20230820_AChSensor_Slice_003_puffing_60X/20230820_AChSensor_Slice_003FLIM049.mat'
% CycleIdentification = {29 0};  % '/Volumes/yaochen/Active/Pingchuan/2023Fall/puffing_SliceMode/20230820_AChSensor_Slice_001_puffing_60X/20230820_AChSensor_Slice_001FLIM029.mat'
% CycleIdentification = {49 0}; % '/Volumes/yaochen/Active/Pingchuan/2023Fall/puffing_SliceMode/20230820_AChSensor_Slice_002_puffing_60X/20230820_AChSensor_Slice_002FLIM010.mat'
% CycleIdentification = {87 0}; % '/Volumes/yaochen/Active/Pingchuan/2023Fall/puffing_SliceMode/20230820_AChSensor_Slice_002_puffing_60X/20230820_AChSensor_Slice_002FLIM087.mat'
% CycleIdentification = {122 0}; % '/Volumes/yaochen/Active/Pingchuan/2023Fall/puffing_SliceMode/20230820_AChSensor_Slice_002_puffing_60X/20230820_AChSensor_Slice_002FLIM122.mat'
% CycleIdentification = {159 0}; % '/Volumes/yaochen/Active/Pingchuan/2023Fall/puffing_SliceMode/20230820_AChSensor_Slice_002_puffing_60X/20230820_AChSensor_Slice_002FLIM159.mat'
% CycleIdentification = {3 0}; % '/Volumes/yaochen/Active/Pingchuan/2023Fall/puffing_SliceMode/20230820_AChSensor_Slice_003_puffing_60X/20230820_AChSensor_Slice_003FLIM003.mat'
% CycleIdentification = {44 0}; % '/Volumes/yaochen/Active/Pingchuan/2023Fall/puffing_SliceMode/20230820_AChSensor_Slice_003_puffing_60X/20230820_AChSensor_Slice_003FLIM044.mat'
% CycleIdentification = {85 0}; % '/Volumes/yaochen/Active/Pingchuan/2023Fall/puffing_SliceMode/20230820_AChSensor_Slice_003_puffing_60X/20230820_AChSensor_Slice_003FLIM044.mat'
% CycleIdentification = {123 0}; % '/Volumes/yaochen/Active/Pingchuan/2023Fall/puffing_SliceMode/20230820_AChSensor_Slice_003_puffing_60X/20230820_AChSensor_Slice_003FLIM123.mat'
% CycleIdentification = {11 0}; % '/Volumes/yaochen/Active/Pingchuan/2023Fall/puffing_SliceMode/20230821_AChSensor_Slice_001_puffing_60X/20230821_AChSensor_Slice_001FLIM011.mat'
% CycleIdentification = {49 0}; % '/Volumes/yaochen/Active/Pingchuan/2023Fall/puffing_SliceMode/20230821_AChSensor_Slice_001_puffing_60X/20230821_AChSensor_Slice_001FLIM049.mat'
% CycleIdentification = {91 0}; % '/Volumes/yaochen/Active/Pingchuan/2023Fall/puffing_SliceMode/20230821_AChSensor_Slice_001_puffing_60X/20230821_AChSensor_Slice_001FLIM091.mat'
% CycleIdentification = {138 0}; % '/Volumes/yaochen/Active/Pingchuan/2023Fall/puffing_SliceMode/20230821_AChSensor_Slice_001_puffing_60X/20230821_AChSensor_Slice_001FLIM0128.mat'
% CycleIdentification = {4 0};  % '/Volumes/yaochen/Active/Pingchuan/2023Fall/puffing_SliceMode/20230821_AChSensor_Slice_002_puffing_60X/20230821_AChSensor_Slice_002FLIM004.mat'
% CycleIdentification = {47 0}; % '/Volumes/yaochen/Active/Pingchuan/2023Fall/puffing_SliceMode/20230821_AChSensor_Slice_002_puffing_60X/20230821_AChSensor_Slice_002FLIM047.mat'
% CycleIdentification = {125 0}; % '/Volumes/yaochen/Active/Pingchuan/2023Fall/puffing_SliceMode/20230821_AChSensor_Slice_002_puffing_60X/20230821_AChSensor_Slice_002FLIM125.mat'
% CycleIdentification = {4 0;5 0;6 0}; % '/Volumes/yaochen/Active/Pingchuan/2021SPR/FLIM/0308AKARIUEHPC001/0308AKARIUEHPC001FLIM020.mat'
% CycleIdentification = {3 0;4 0}; % '/Volumes/yaochen/Active/Pingchuan/2024Fall/20240703_nLightG_HEK_002/20240703_nLightG_HEK_002FLIM003.mat'
% CycleIdentification = {3 0}; % '/Volumes/yaochen/Active/Pingchuan/2024Fall/20240703_5HTFLIMSensor_HEK_002/20240703_5HTFLIMSensor_HEK_002FLIM003.mat'
% CycleIdentification = {6 0}; % '/Volumes/yaochen/Active/Pingchuan/2024Fall/20240703_5HTFLIMSensor_HEK_001/20240703_5HTFLIMSensor_HEK_001FLIM006.mat'
% CycleIdentification = {5 0}; % '/Volumes/yaochen/Active/Pingchuan/2024Fall/FLIMDA05/20240718_FLIMDA05_HEK_001/20240718_FLIMDA05_HEK_001FLIM005.mat'
% CycleIdentification = {4 0}; % '/Volumes/yaochen/Active/Pingchuan/2024Fall/FLIMDA05/20240718_FLIMDA05_HEK_002/20240718_FLIMDA05_HEK_002FLIM004.mat'
% CycleIdentification = {4 0}; % '/Volumes/yaochen/Active/Pingchuan/2024Fall/FLIMDA05/20240718_FLIMDA05_HEK_003/20240718_FLIMDA05_HEK_003FLIM004.mat'
% CycleIdentification = {5 0;6 0}; % /Volumes/yaochen/Active/Pingchuan/2024Fall/20240703_nLightG_HEK_001
% CycleIdentification = {46 0;47 0}; % '/Users/pingchuanma/Downloads/David data/20241019_AKARWildForskTemp/20241019_AKARWildForskTempFLIM041.mat'
CycleIdentification = {9 0;10 0}; %'/Users/pingchuanma/Downloads/David data/20241019_AKARMutTemp/20241019_AKARMutTempFLIM006.mat'

% This section is only applicable to the situation where in one set of
% imaging,there are multiple episodes, including multiple positions imaging during
% drug flow-in and single position imaging for drug puffing or optogenetics
% or eletrical stimulation.
% If not this situation, leave the variable redefine as non-1 and non-0
% value.

global Epochstart Epochend redefine NonValidAcqs
% redefine=0 means excluding acquisitions before and after EpochStart and
% EpochEnd, but can still have multiple positions.
% redefine=1 when analyzing a puffing episode with 1 cycle position.
% For all other scenarios, choose a number that is not 0 or 1 or 3...
% define the starting and ending acq number for this episode.

redefine = 2 ;



Epochstart = 44;
Epochend = 73;
NonValidAcqs = [54];

% Is this a new set?
isNewSet = 1;

% Do you need to reload the images?
getImages = 1; % 0 = no, 1 = yes

%% Before Initialization, Prepare Some Variables



% Photon value threshold
valPhoton_threshold = 20000; %200,000 is a reasonable value for 20 frames; it gives a stdev of 0.0035ns, 2.8X0.01ns.

% function links
funcLink = [];

funcLink.findDendriteShift =...
    'Yao_findDendriteShift_v7';
funcLink.findNucleus =...
    'Yao_findNucleus_v17';

funcLink.findNucleus_func_List = char(...
    'None','User Input','Mask',...
    'Yao_findNucleus_func_v4b',...
    'Yao_findNucleus_func_v5b',...
    'Yao_findNucleus_func_v6b' );
funcLink.findNucleus_func_default =...
    'Yao_findNucleus_func_v4b';

funcLink.findNucleusMask =...
    'Yao_findNucleusMask_v9b';

funcLink.getZones =...
    'Yao_generic_zoneID_v3';



funcLink.loadImage =...
    'Yao_generic_loadImage_v3';


%%

dendriteOpt = [];
nucleusOpt = [];

dendriteOpt.rotation = 0; % 0 = off, 1 = on
% dendriteOpt.isolateBeforeShift = 0; % 0 = off, 1 = on

nucleusOpt.borderThreshold = 10;
% Occurs during findCell
%   Will get a list of all Cell IDs. From this list, it will go through
%   each image and collect the centroid position of each cell. For a given
%   Cell ID, it will find the centroid furthest from the border. If that
%   distance is less than borderThreshold, that Cell ID will be marked for
%   deletion. All cells with that Cell ID will be removed.

nucleusOpt.valleyDetection = [0 0]; % 0 = off, 1 = on
% Occurs duing cell isolation 
%   Try to identify valleys in isolated cells which may indicate a split
%   between two adjacent cells

nucleusOpt.checkAppendages = [0 0]; % 0 = off, 1 = on
% Occurs after cell isolation and indexing
%   Iterative process to remove appendages1

% nucleusOpt.cellspercycle = [2]; % Yao: To be continued.

nucleusOpt.erodeCell_calc = 2;
% Description



% Color codes
colorList = char('r','y','g','c','b');
%   Cell 1 will be red
%   Cell 2 will be yellow
%   Cell 3 will be green
%   etc



% Pixel Count threshold
%   threshold = f( zoomFactor )
%       400 = f( 10 )
%       200 = f(  5 )
% % % temp = [10 400;5 200];
temp = [10 400;5 200];
%
%           ( y2 - y1 )
%       m = ------------
%           ( x2 - x1 )
%
%       b = y1 - m*x1
%
temp_m = zeros( size(temp,1)-1 ,1);
for i = 1:size(temp,1)-1
    temp_m(i) = (temp(i+1,2)-temp(i,2))/(temp(i+1,1)-temp(i,1));
end
temp_m = mean(temp_m);
temp_b = zeros( size(temp,1) ,1);
for i = 1:size(temp,1)
    temp_b(i) = temp(i,2)-temp_m*temp(i,1);
end
temp_b = mean(temp_b);
cellPixelCount_threshold_b = temp_b;
cellPixelCount_threshold_m = temp_m;
clear temp temp_b temp_m



%% Things to be aware of
%   Cell indexing assumes that if there are predominately two cells, every
%   image that has only 2 cells will have the SAME 2 cells
%
%   Assumes that second imageShift detection (Yao_findCells_VERSION) is
%   accurate
%
%   Determination of nCell_true has a tipping point of 1/4
%       Used in:
%           Yao_findCells_VERSION
%           Yao_identify_cellIndex_VERSION
%
%       In function:
%           Yao_findCells_calc__nCell_true
%
%   Threshold difference for origin distance set at 20 pixels
%   (Yao_identify_cellIndex_VERSION)



%% Begin initialization
global stateYao



stateYao.StartSettings.CycleIdentification = CycleIdentification;
stateYao.StartSettings.valPhoton_threshold = valPhoton_threshold;
stateYao.StartSettings.dendriteOpt = dendriteOpt;
stateYao.StartSettings.nucleusOpt = nucleusOpt;
stateYao.StartSettings.colorList = colorList;
stateYao.StartSettings.cellPixelCount_threshold_b = cellPixelCount_threshold_b;
stateYao.StartSettings.cellPixelCount_threshold_m = cellPixelCount_threshold_m;

stateYao.StartSettings.funcLink = funcLink;
stateYao.StartSettings.originalFile=spc.originalFile; % Write original file for fitting to stateYao (Yao 2022-2-21)
stateYao.StartSettings.LUTOffset=spc.switchess; % Write lookup table parameters, etc. to stateYao (Yao 2022-2-21)
stateYao.StartSettings.fits=spc.fits; % write fitting parameters, chi2 to stateYao (Yao 2022-2-21)

clear CycleIdentification
clear valPhoton_threshold
clear dendriteOpt nucleusOpt
clear colorList
clear cellPixelCount_threshold_b cellPixelCount_threshold_m

clear funcLink



[continueRun] = Yao_initialize__run_all(isNewSet);



%% Do we need to re-grab images?
if isNewSet || getImages
    Yao_initialize__getImages
end



%% Do we need to get initial shift?
if isNewSet || getImages
    Yao_initialize__getShift_initial
end



%% Run - Dendrites
for iCycle = 1:size( stateYao.curRun ,1)
    numCycle = stateYao.curRun(iCycle);
    
    if any( numCycle == stateYao.CycleDendrite )
        % Dendrite -> Search for shift
        %   Mask was found during initialization
        
        
        hdlProgDendrite = waitbar(0,...
            sprintf('Getting Dendrite Shift for Cycle %d',numCycle) );
        
        
        for iImg = 1:size( stateYao.CyclePositions ,1)
            if stateYao.CyclePositions(iImg,numCycle) ~= 0
            if stateYao.ignoreImage(iImg,numCycle) == 0
                
                
                if ishandle(hdlProgDendrite)
                waitbar(...
                    iImg/size(stateYao.CyclePositions,1),...
                    hdlProgDendrite)
                drawnow
                end
                
                
                eval( sprintf('%s(numCycle,iImg)',...
                    stateYao.funcLink.findDendriteShift) )

            end
            end
        end
        
        if ishandle(hdlProgDendrite)
        close(hdlProgDendrite)
        drawnow
        end
        
    end
    
end





%% Run - Nuclei
for iCycle = 1:size( stateYao.curRun ,1)
    numCycle = stateYao.curRun(iCycle);
    
    if any( numCycle == stateYao.CycleNucleus )
        % Find cells first
        Yao_findCells(numCycle)
    end
end

for iCycle = 1:size( stateYao.curRun ,1)
    numCycle = stateYao.curRun(iCycle);
    
    if any( numCycle == stateYao.CycleNucleus )
        % Get nucleus
        
        str = sprintf('Finding Nuclei for Cycle %d...',numCycle);
        hdlProgFindNucleus = waitbar(0,str);
        
        for iImg = 1:size( stateYao.CyclePositions ,1)
            if stateYao.CyclePositions(iImg,numCycle) ~= 0
                if stateYao.ignoreImage(iImg,numCycle) == 0
                    
                    if ishandle(hdlProgFindNucleus)
                        waitbar(...
                            iImg/size( stateYao.CyclePositions ,1),...
                            hdlProgFindNucleus)
                        drawnow
                    end
                    
                    eval( sprintf('%s(numCycle,iImg)',...
                        stateYao.funcLink.findNucleus) )
                    
                end
            end
        end
        
        if ishandle(hdlProgFindNucleus)
        close(hdlProgFindNucleus)
        drawnow
        end
        
    end
end

for iCycle = 1:size( stateYao.curRun ,1)
    numCycle = stateYao.curRun(iCycle);
    
    if any( numCycle == stateYao.CycleNucleus )
        % Do we need to create masks?
        eval(sprintf('%s(%s)',...
            stateYao.funcLink.findNucleusMask,...
            sprintf('%s',...
            'numCycle') ))
    end
end

%%
Yao_launchGui