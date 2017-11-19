# AFM_SMFS
Matlab coding for AFM SMFS raw data post-processing > localisation and classification of rupture events

This repository contains Matlab codes to process Atomic Force Micoroscopy raw single molecule force spectroscopy data.
In the present context, cantilevers were functionalised to target hyaluronic acid molecules on live cells. 
This data processing allows for distinguishing between hyaluronic acide molecules anchored or not anchored to the cell cytoskeleton by looking at the probe/molecule rupture events.
Similar methodologies were reported here: [Chu C. et al. 2013](http://journals.plos.org/plosone/article?id=10.1371/journal.pone.0064187), [Sariisik E. et al. 2015](http://www.sciencedirect.com/science/article/pii/S0006349515007857?via%3Dihub)

#### Raw data
The raw data are force-spectroscopy .txt files from AFM experiments. They contain four columns: cantilever height [m], cantilever vertical deflection [N], series time [s], segment time [s].
All the experiments in this context were carried out with a Nanowizard 3 microscope from JPK. The built-in software provide .txt files in this form (comments are preceded by #)

#### Pre-processed data
Raw data (_input_) are processed individually with the matlab code AFM1_contactpoint.m.
This code is needed to:
* fit the contact point with the ratio-of-variance method (see [Gavara N. 2016](https://www.nature.com/articles/srep21267)),
* ask the user if happy with the contact point fitting,
* correct the drift between extend and retract baselines,
* correct for tip-sample separation.
Pre-processed data are obtained as _output_.

#### Localise and classify probe/molecule rupture events
Pre-processed data (_input_) are analysed with the matlab code AFM2_findpeaks.m to localise and classify rupture events.
This code is needed to:
* localise rupture events by screening the first derivative of the force signal,
* classify rupture events as cytoskeleton-anchored ruptues or membrane tether ruptures.
The _ouput_ consists of two matrices called _csk_ (for cytoskeleton-anchored) and _tet_ (for membrane tethers) which contains all the classified rupture events for the pre-processed data.

#### Detailed code description
##### AFM1_contactpoint.m
This algorithm takes raw file from AFM microscope (.txt) as input and fit the contact point, correct retract drift and tip-sample separation.
New .txt files are saved as ouput in a folder of choice containing cantilever height, vertical deflection, time and segment.

0. _INPUT_: information about the performed AFM experiment need to be entered by the user (spring constant of the cantilever used, input folder and matlab working folder)
1. open input folder and list file names for next step
2. FOR cycle which opens one file at the time from the input folder and perform post-processing steps
..1. open file
..2. save data from file into arrays
..3. fit contact point on extend curve
..4. plot data after fitting the CP for user verification
..5. save pre-processed file as .txt files in the output folder

##### AFM2_findpeaks.m
This algorithm takes pre-processed data as input and localise/classify rupture events on the retract curve.
Two matrices containing the classified events details are returned as output.
Cytoskeleton-anchored rupture events are preceded by a rise in force due to the spring-like behaviour of the actin cytoskeleton; membrane tether rupture events are preceded by a plateau in force.
The slope of the curve prior to rupture is therefore used as a classifier: if "horizontal" the rupture is classified as a membrane tether, if at "higher angles" the rupture is classified as a cytoskeleton-anchored.
To define a slope as "horizontal" the baseline of the extend curve of the acquired data can be considered (user input): this holds zero force and therefore its variations in slope should correspond to the one of a plateau.

0. _INPUT_: information about the performed AFM experiment need to be entered by the user (thresholds for rupture event classification, input folder and matlab working folder)
1. open input folder and list file names for next step
2. initialise rupture events counter
3. FOR cycle which opens one file at the time from the input folder and perform post-processing steps
..1. open file
..2. save data from file into arrays
..3. find derivative of smoothed data
..4. localise rupture events by thresholding peaks on the derivative
..5. classify peaks as cytoskeleton-anchored or membrane tethers
4. save rupture events in correspondent output matrix (_csk_ or _tet_); each matrix contains all classified rupture events, in terms of distance from contact point (first column), force at rupture (second column), slope prior to rupture (third column) and data ID (fourth column).
