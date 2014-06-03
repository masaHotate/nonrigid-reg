% bundle adjustment

addpath( './lib/file_management' );
addpath( genpath( 'vendor/coherent-point-drift' ) );
addpath('vendor/kdtree/lib' )
addpath('vendor/kdtree-mex/' );
addpath('vendor/mahalanobis/' );
addpath('lib/anisotropic_filter/');

R =  [ 0.9101   -0.4080    0.0724 ;
       0.4118    0.8710   -0.2681 ;
       0.0463    0.2738    0.9607 ];
t = [ 63.3043,  234.5963, -46.8392 ];

% stop and restart parallel pool
%delete(gcp)
%parpool('LocalProfile1')

n = 12;
scans=cell(n,1);
scans_sampled=cell(n,1);
scans_rigid = cell(n,1);
scans_nonrigid = cell(n,1);
for q=1:n
    
filename = sprintf( '~/Data/PlantDataPly/plants_converted82-%03d-clean-clear.ply', q-1 );
[Elements_0,varargout_0] = plyread(filename);


X = [Elements_0.vertex.x';Elements_0.vertex.y';Elements_0.vertex.z']';

for j=1:q-1
        X_dash = R*X' + repmat(t,size(X,1),1)';
        X = X_dash';
end

scans_sampled{q} = X(1:20:end,:);
scans{q} = scans_sampled{q};
end


opt.viz = 1;
opt.scale = 0;
% allow for reflections -> rot = 0
opt.rot = 0;
opt.method = 'nonrigid_lowrank';
opt.outliers = 0.3;
opt.lambda = 1;
opt.beta = 90;
opt.normalize = 1;
opt.max_it = 80;
opt.tol = 1e-10;
opt.fgt = 2;

%{
Y_nearest = cell(12,1);
idx_nearest_x = cell(12,1);
points = cell(12,1);
for i=2:12
    [idx_nearest_x{i},points{i},Y_nearest{i}] = getMutualNeighbours( scans{1}, scans{i} );
end

Y_c = [];
for j=1:size(scans{1},1)
    Y_c = [Y_c ; [getCentroidOfPointsAt( Y_nearest, j )]];
    
end
%}
%Y_c_2 = getMutualNeighbourCentroids( scans, 1 );

%outlier_vals = [ 0.7 0.6 0.5 0.4 0.3 0.3 0.4 0.5 0.6 0.6 0.7 0.7];
K = 10000;
h = 120;
e = 10;
p = 8;

for i=1:12      
    for j=1:12
        sprintf( 'outer loop #%d, scan #%d', [i j])
        scans_c = getMutualNeighbourCentroids( scans, j );
        T = cpd_register(scans_c,scans{j},opt);
        scans{j} = T.Y;
        %[cp,dist,treeroot_y] = kdtree(scans{j+1},scans{j});
        %tree_y = kdtree_build(Y);
        %[idx_y(i)] = kdtree_k_nearest_neighbors( tree_y, X(i,:), k );
    end
end