classdef (ConstructOnLoad = true) RATWALK < handle
    % RATWALK is a handle class for analysing open arena rat behaviour test
    % Load raw video footage and use binary thresholding to capture subject
    % outline and box outline.  Outline data is saved for later analysis
    %
    % Units: length=m, time=s, mass=g, force=N
    %----------------------------------------
    properties ( Constant = true )
        g = 9.81; % Earth gravitational acceleration
        analyser_path = cat(2,'.',filesep,'ANALYSER',filesep); % location of analyser functions
    end
    properties ( SetAccess = public )
        name = [];      % identification name
        mass = 200;     % default rat mass of 200g
        max_speed = 3;  % maximum speed set at 3m/s or ~10km/h
        max_floorlength = sqrt(2*(0.75^2));  % default floor area of a square with side of 75cm
        max_ratlength = 0.75/5; % estimated maximum lengh of rat
        max_ratwidth = 0.75/10; % estimated maximum width of rat
        hindlimb_length = 0.01;   % estimated hindlimb length of rat
        pixel_res;      % use max_floorlength to workout pixel resolution
        floor_range;    % image value bound for floor
        wall_range;     % image value bound for wall
        rat_range;      % image value bound for rat
        abstract_av;    % abstracted footage containing objects boundary vector
        raw_av_obj;     % handle object for loading video
    end
    properties ( SetAccess = private )
        
    end
    %----------------------------------------
    methods ( Access = public )
        function obj = RATWALK( varargin )
            %constructor function
            obj.abstract_av=struct('frame_width',[],...
                'frame_height',[],...
                'frame_num',[],...
                'frame_rate',15,...
                'time',[],...
                'object',[]);
            obj.abstract_av.object=struct('name',{'floor','wall','rat'},...
                'boundary',{{[]},{[]},{[]}},...
                'skeleton',{{[]},{[]},{[]}},...
                'position',{[],[],[]},...
                'colour',{'b','g','r'});
        end
    end
    
    methods ( Access = public)
        obj = open_ratwalk( obj, filename );              % open ratwalk variable
        [ status ] = save_ratwalk( obj );       % save ratwalk variable
        [ status ] = load_raw_video( obj );     % ask for raw video file to load
        [ status ] = export_abstract_video( obj );  % export abstracted boundary video

        [ status ] = initial_process( obj, image_panel_handle, manual );        % Process initial frames to guess boundaries
        [ status ] = process_frames( obj, image_panel_handle, showav );         % Process the whole video
        [ status ] = display_frames( obj, image_panel_handle, framenum, vidtype );         % Process the whole video
        
        text = display_data_analyser( obj, output_handle, index );     % find data analysis functions
    end
    
    methods ( Access = private)
       
    end
end