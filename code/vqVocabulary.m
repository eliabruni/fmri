% -------------------------------------------------------------------------
%                                                    Configuration settings
% -------------------------------------------------------------------------


% adds paths to Matlab's search path
addpath('/Users/eliabruni/git/provisional/toolbox')
%run(fullfile('/Users/eliabruni/git/provisional/toolbox',helpers.startup.vsemStartup


% vocabulary and concept folders
configuration.vocabularyPath = '/Users/eliabruni/git/fmri/data/vocabs/vocab.mat'; % desired location of the vocabulary
configuration.conceptSpacePath = '/Users/eliabruni/git/fmri/data/spaces/conceptSpace.mat'; % desired location of the concepts

% image dataset and annotation folders
configuration.imagesPath = fullfile(vsemRoot, 'data/JPEGImages');
configuration.annotationPath = fullfile(vsemRoot,'data/Annotations');

% number of visual words to compute the visual vocabulary for
configuration.vocabularySize = 100;

% number of images to be used in the creation of visual vocabulary;
% if limit < 1, no discount is applied
configuration.vocabularyImageLimit = -1;


% -------------------------------------------------------------------------
%                                                         Feature extractor
% -------------------------------------------------------------------------


% dataset object creation
dataset = datasets.VsemDataset(configuration.imagesPath, 'annotationFolder',...
    configuration.annotationPath);

% featureExtractor object creation
featureExtractor = vision.features.PhowFeatureExtractor('color', 'hsv');


% -------------------------------------------------------------------------
%                                                                Vocabulary
% -------------------------------------------------------------------------



% image discount
KmeansVocabulary = vision.vocabulary.KmeansVocabulary('voc_size',...
    configuration.vocabularySize, 'trainimage_limit',...
    configuration.vocabularyImageLimit);

% train vocabulary
vocabulary = KmeansVocabulary.trainVocabulary(dataset, featureExtractor);

% save vocabulary
save(configuration.vocabularyPath,'vocabulary');

