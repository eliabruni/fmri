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

% localization tipe, 'global', 'surrounding' or 'object
configuration.localization = 'object';

% spatial binning (including spatial information from image partitions)
configuration.squareDivisions = 2;
configuration.horizontalDivisions = 3;

configuration.demoType = 'tiny';

% tiny settings
if strcmpi(configuration.demoType, 'tiny')
    configuration.vocabularySize = 10;
    % number of images to be used in the creation of visual vocabulary;
    % if limit < 1, no discount is applied
    configuration.vocabularyImageLimit = 50;
    % number of images to calculate the concept representation from; if
    % limit < 1, no discount is applied
    configuration.conceptImageLimit = 20;
end



% -------------------------------------------------------------------------
%                                                         Feature extractor
% -------------------------------------------------------------------------


% dataset object creation
dataset = datasets.VsemDataset(configuration.imagesPath, 'annotationFolder',...
    configuration.annotationPath);

% featureExtractor object creation
featureExtractor = vision.features.PhowFeatureExtractor('color', 'gray');


% -------------------------------------------------------------------------
%                                                                Vocabulary
% -------------------------------------------------------------------------


if exist(configuration.vocabularyPath,'file')
    load(configuration.vocabularyPath);
else
    
    % visual vocabulary generator object and visual vocabulary creation
    if strcmpi(configuration.demoType, 'tiny')
        % image discount
        KmeansVocabulary = vision.vocabulary.KmeansVocabulary('voc_size',...
            configuration.vocabularySize, 'trainimage_limit',...
            configuration.vocabularyImageLimit);
    else
        % no image discount
        KmeansVocabulary = vision.vocabulary.KmeansVocabulary('voc_size',...
            configuration.vocabularySize);
    end
    
    vocabulary = KmeansVocabulary.trainVocabulary(dataset, featureExtractor);
    save(configuration.vocabularyPath,'vocabulary');
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Intervene here with the tuning

fullConceptsExtractorOpts = {'subbin_norm_type', 'l1', 'norm_type', 'l1',...
    'post_norm_type', 'l1','kermap', 'homker'};


% -------------------------------------------------------------------------
%                                                                  Concepts
% -------------------------------------------------------------------------

% histogram and concept extractor objects creation and concept extraction
histogramExtractor = vision.histograms.bovwhistograms.VsemHistogramExtractor(...
    featureExtractor, vocabulary, 'localization', configuration.localization,...
    'quad_divs', configuration.squareDivisions, 'horiz_divs', configuration.horizontalDivisions);

conceptExtractor = concepts.extractor.VsemConceptsExtractor(fullConceptsExtractorOpts{:});

if strcmpi(configuration.demoType, 'tiny')
    % image discount
    conceptSpace = conceptExtractor.extractConcepts(dataset, histogramExtractor,...
        'imageLimit', configuration.conceptImageLimit);
else
    
    conceptSpace = conceptExtractor.extractConcepts(dataset, histogramExtractor);
end


save(configuration.conceptSpacePath, 'conceptSpace');

% -------------------------------------------------------------------------
%                                                           Transformations
% -------------------------------------------------------------------------

% reweighting concept matrix
conceptSpace = conceptSpace.reweight('reweightingFunction', @concepts.space.transformations.reweighting.pmiReweight);


% -------------------------------------------------------------------------
%                                                              Benchmarking
% -------------------------------------------------------------------------

% computing similarity score with similarity extractor
similarityExtractor = benchmarks.helpers.SimilarityExtractor();
similarityBenchmark = benchmarks.SimilarityBenchmark('benchmarkName','pascal');

[score, pValue] = similarityBenchmark.computeBenchmark(conceptSpace, similarityExtractor);

% printing results
fprintf('The obtained visual concepts performed with a score of %4.2f%% and a significance (p value) of %4.3f on the Pascal similarity benchmark.\n',score*100, pValue);