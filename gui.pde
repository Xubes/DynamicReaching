/* =========================================================
 * ====                   WARNING                        ===
 * =========================================================
 * The code in this tab has been generated from the GUI form
 * designer and care should be taken when editing this file.
 * Only add/edit code inside the event handlers i.e. only
 * use lines between the matching comment tags. e.g.

 void myBtnEvents(GButton button) { //_CODE_:button1:12356:
     // It is safe to enter your event code here  
 } //_CODE_:button1:12356:
 
 * Do not rename this tab!
 * =========================================================
 */

public void btnResetDeltaClick(GButton source, GEvent event) { //_CODE_:btnResetDelta:933479:
  //println("btnReset - GButton >> GEvent." + event + " @ " + millis());
  resetDelta();
} //_CODE_:btnResetDelta:933479:

public void btnSpinClick(GButton source, GEvent event) { //_CODE_:btnSpin:521123:
  //println("btnSpin - GButton >> GEvent." + event + " @ " + millis());
  // Reset position on first spin of trial.
  btnNextTrial.setEnabled(false);
  btnPrevTrial.setEnabled(false); 
  long startTime;
  resetPosition();
  
  startTime = millis();
  while(millis()-startTime<100){}; // busy wait 100 millis to let sensor update
  
  double startPosition = anglePosition;
  startTime = millis();
  if(spin(degrees2Rotate,direction)){
    double endPosition = anglePosition;
    double stopTime = millis();
    double avgVelocity = 1000 * Math.abs( (endPosition-startPosition)/(stopTime-startTime));
    if(currentTrial!=null){
        currentTrial.direction = direction;
        currentTrial.speedToward = avgVelocity;
        currentTrial.initPosToward = startPosition;
        currentTrial.termPosToward = endPosition;
        currentTrial.complete = true;
      }
    direction *= -1;  // next spin will go in opposite direction
  }
  
  if(currentTrial.isComplete()){
    nextTrial();
  }
} //_CODE_:btnSpin:521123:

public void csliderBrakeChange(GCustomSlider source, GEvent event) { //_CODE_:csliderBrake:657048:
  brake = source.getValueI();
  //println("csliderBrake - GCustomSlider >> GEvent." + event + " @ " + millis());
} //_CODE_:csliderBrake:657048:

public void buttonReverseClick(GButton source, GEvent event) { //_CODE_:buttonReverse:305135:
  direction *= -1;
  //println("buttonReverse - GButton >> GEvent." + event + " @ " + millis());
} //_CODE_:buttonReverse:305135:

public void csliderPowerChange(GCustomSlider source, GEvent event) { //_CODE_:csliderPower:301311:
  power = source.getValueI();
  //println("custom_slider1 - GCustomSlider >> GEvent." + event + " @ " + millis());
} //_CODE_:csliderPower:301311:

public void buttonResetPositionClick(GButton source, GEvent event) { //_CODE_:buttonResetPosition:614711:
  resetPosition();
  //println("buttonResetPosition - GButton >> GEvent." + event + " @ " + millis());
} //_CODE_:buttonResetPosition:614711:

public void btnGenerateTrialsClicked(GButton source, GEvent event) { //_CODE_:btnGenerateTrials:224544:
  trials2Run = generateTrials(trialsPerBlock, direction);
  // Print trials to console
  for(Trial t : trials2Run) System.err.println(t);
  
  // Set the current trial.
  li = trials2Run.listIterator();
  setTrial(li.next());
  source.setEnabled(false);
  //println("btnGenerateTrials - GButton >> GEvent." + event + " @ " + millis());
} //_CODE_:btnGenerateTrials:224544:

public void btnNextTrialClick(GButton source, GEvent event) { //_CODE_:btnNextTrial:908733:
  nextTrial();
  //println("btnNextTrial - GButton >> GEvent." + event + " @ " + millis());
} //_CODE_:btnNextTrial:908733:

public void buttonSaveClick(GButton source, GEvent event) { //_CODE_:buttonSave:860221:
  selectOutput("Select file to save to.", "saveToFile");
} //_CODE_:buttonSave:860221:

public void btnPrevTrialClick(GButton source, GEvent event) { //_CODE_:btnPrevTrial:460108:
  previousTrial();
  //println("btnPrevTrial - GButton >> GEvent." + event + " @ " + millis());
} //_CODE_:btnPrevTrial:460108:

public void btnSetHighClick(GButton source, GEvent event) { //_CODE_:btnSetHigh:288642:
  settings[HIGH][0] = power;
  settings[HIGH][1] = brake;
  //println("btnSetHigh - GButton >> GEvent." + event + " @ " + millis());
} //_CODE_:btnSetHigh:288642:

public void btnSetMediumClick(GButton source, GEvent event) { //_CODE_:btnSetMedium:912663:
  settings[MEDIUM][0] = power;
  settings[MEDIUM][1] = brake;
  //println("btnSetMedium - GButton >> GEvent." + event + " @ " + millis());
} //_CODE_:btnSetMedium:912663:

public void btnSetBaselineClick(GButton source, GEvent event) { //_CODE_:btnSetBaseline:335533:
  settings[LOW][0] = power;
  settings[LOW][1] = brake;
  //println("btnSetBaseline - GButton >> GEvent." + event + " @ " + millis());
} //_CODE_:btnSetBaseline:335533:

public void btnBaselineTrialClick(GButton source, GEvent event) { //_CODE_:btnBaselineTrial:476833:
  if(baselineFlag){
    System.err.println("Resuming experiment");
    setTrial(tempTrial);
    source.setText("Load baseline");
  }
  else{
    System.err.println("Loading baseline trial");
    tempTrial = currentTrial;
    setTrial(baselineTrial);
    source.setText("Resume experiment");
  }
  baselineFlag = !baselineFlag;
  redraw();  
  //println("btnBaselineTrial - GButton >> GEvent." + event + " @ " + millis());
} //_CODE_:btnBaselineTrial:476833:

public void btn180TrialClick(GButton source, GEvent event) { //_CODE_:btn180Trial:288071:
  if(baseline180Flag){
    System.err.println("Resuming experiment");
    setTrial(tempTrial);
    source.setText("Load 180");
  }
  else{
    System.err.println("Loading 180 degree trial");
    tempTrial = currentTrial;
    setTrial(baseline180Trial);
    source.setText("Resume experiment");
  }
  baseline180Flag = !baseline180Flag;
  //println("btn180Trial - GButton >> GEvent." + event + " @ " + millis());
} //_CODE_:btn180Trial:288071:

public void btnSet180Click(GButton source, GEvent event) { //_CODE_:btnSet180:750451:
  settings[LOW_180][0] = power;
  settings[LOW_180][1] = brake;
  //println("btnSet180 - GButton >> GEvent." + event + " @ " + millis());
} //_CODE_:btnSet180:750451:



// Create all the GUI controls. 
// autogenerated do not edit
public void createGUI(){
  G4P.messagesEnabled(false);
  G4P.setGlobalColorScheme(GCScheme.BLUE_SCHEME);
  G4P.setCursor(ARROW);
  if(frame != null)
    frame.setTitle("Sketch Window");
  btnResetDelta = new GButton(this, 140, 20, 110, 50);
  btnResetDelta.setText("Reset Delta");
  btnResetDelta.setLocalColorScheme(GCScheme.PURPLE_SCHEME);
  btnResetDelta.addEventHandler(this, "btnResetDeltaClick");
  btnSpin = new GButton(this, 110, 330, 140, 50);
  btnSpin.setText("Spin!");
  btnSpin.setTextBold();
  btnSpin.setLocalColorScheme(GCScheme.GREEN_SCHEME);
  btnSpin.addEventHandler(this, "btnSpinClick");
  labelSensorInfo = new GLabel(this, 40, 80, 210, 120);
  labelSensorInfo.setOpaque(true);
  csliderBrake = new GCustomSlider(this, 420, 20, 280, 70, "red_yellow18px");
  csliderBrake.setShowValue(true);
  csliderBrake.setShowLimits(true);
  csliderBrake.setTextOrientation(G4P.ORIENT_LEFT);
  csliderBrake.setRotation(PI/2, GControlMode.CORNER);
  csliderBrake.setLimits(65, 300, 0);
  csliderBrake.setNbrTicks(19);
  csliderBrake.setShowTicks(true);
  csliderBrake.setNumberFormat(G4P.INTEGER, 0);
  csliderBrake.setLocalColorScheme(GCScheme.ORANGE_SCHEME);
  csliderBrake.setOpaque(true);
  csliderBrake.addEventHandler(this, "csliderBrakeChange");
  buttonReverse = new GButton(this, 40, 330, 60, 50);
  buttonReverse.setText("Reverse");
  buttonReverse.addEventHandler(this, "buttonReverseClick");
  labelPowerSlider = new GLabel(this, 270, 300, 70, 20);
  labelPowerSlider.setText("Power");
  labelPowerSlider.setLocalColorScheme(GCScheme.GREEN_SCHEME);
  labelPowerSlider.setOpaque(true);
  labelBrakeSlider = new GLabel(this, 350, 300, 70, 20);
  labelBrakeSlider.setText("Brake");
  labelBrakeSlider.setLocalColorScheme(GCScheme.ORANGE_SCHEME);
  labelBrakeSlider.setOpaque(true);
  csliderPower = new GCustomSlider(this, 340, 20, 280, 70, "blue18px");
  csliderPower.setShowValue(true);
  csliderPower.setShowLimits(true);
  csliderPower.setTextOrientation(G4P.ORIENT_LEFT);
  csliderPower.setRotation(PI/2, GControlMode.CORNER);
  csliderPower.setLimits(65, 200, 50);
  csliderPower.setNbrTicks(6);
  csliderPower.setShowTicks(true);
  csliderPower.setNumberFormat(G4P.INTEGER, 0);
  csliderPower.setLocalColorScheme(GCScheme.GREEN_SCHEME);
  csliderPower.setOpaque(true);
  csliderPower.addEventHandler(this, "csliderPowerChange");
  labelDisplay = new GLabel(this, 40, 210, 210, 110);
  labelDisplay.setText("Hi.");
  labelDisplay.setLocalColorScheme(GCScheme.PURPLE_SCHEME);
  labelDisplay.setOpaque(true);
  buttonResetPosition = new GButton(this, 40, 20, 100, 50);
  buttonResetPosition.setText("Reset Position");
  buttonResetPosition.addEventHandler(this, "buttonResetPositionClick");
  btnGenerateTrials = new GButton(this, 450, 20, 120, 39);
  btnGenerateTrials.setText("Generate Trials");
  btnGenerateTrials.setTextBold();
  btnGenerateTrials.setLocalColorScheme(GCScheme.ORANGE_SCHEME);
  btnGenerateTrials.addEventHandler(this, "btnGenerateTrialsClicked");
  btnNextTrial = new GButton(this, 450, 80, 120, 40);
  btnNextTrial.setText("Next Trial");
  btnNextTrial.setTextBold();
  btnNextTrial.setLocalColorScheme(GCScheme.GREEN_SCHEME);
  btnNextTrial.addEventHandler(this, "btnNextTrialClick");
  buttonSave = new GButton(this, 450, 340, 120, 40);
  buttonSave.setText("Save");
  buttonSave.setTextBold();
  buttonSave.setLocalColorScheme(GCScheme.CYAN_SCHEME);
  buttonSave.addEventHandler(this, "buttonSaveClick");
  btnPrevTrial = new GButton(this, 450, 130, 120, 40);
  btnPrevTrial.setText("Previous Trial");
  btnPrevTrial.addEventHandler(this, "btnPrevTrialClick");
  btnSetHigh = new GButton(this, 470, 180, 80, 30);
  btnSetHigh.setText("Set High");
  btnSetHigh.setTextBold();
  btnSetHigh.setLocalColorScheme(GCScheme.RED_SCHEME);
  btnSetHigh.addEventHandler(this, "btnSetHighClick");
  btnSetMedium = new GButton(this, 470, 220, 80, 30);
  btnSetMedium.setText("Set Medium");
  btnSetMedium.setTextBold();
  btnSetMedium.setLocalColorScheme(GCScheme.YELLOW_SCHEME);
  btnSetMedium.addEventHandler(this, "btnSetMediumClick");
  btnSetBaseline = new GButton(this, 470, 260, 80, 30);
  btnSetBaseline.setText("Set Baseline");
  btnSetBaseline.setTextBold();
  btnSetBaseline.setLocalColorScheme(GCScheme.GREEN_SCHEME);
  btnSetBaseline.addEventHandler(this, "btnSetBaselineClick");
  btnBaselineTrial = new GButton(this, 350, 330, 80, 50);
  btnBaselineTrial.setText("Load Baseline");
  btnBaselineTrial.setTextBold();
  btnBaselineTrial.setLocalColorScheme(GCScheme.GREEN_SCHEME);
  btnBaselineTrial.addEventHandler(this, "btnBaselineTrialClick");
  btn180Trial = new GButton(this, 260, 330, 80, 50);
  btn180Trial.setText("Load 180");
  btn180Trial.setTextBold();
  btn180Trial.setLocalColorScheme(GCScheme.PURPLE_SCHEME);
  btn180Trial.addEventHandler(this, "btn180TrialClick");
  btnSet180 = new GButton(this, 470, 300, 80, 30);
  btnSet180.setText("Set 180");
  btnSet180.setTextBold();
  btnSet180.setLocalColorScheme(GCScheme.PURPLE_SCHEME);
  btnSet180.addEventHandler(this, "btnSet180Click");
}

// Variable declarations 
// autogenerated do not edit
GButton btnResetDelta; 
GButton btnSpin; 
GLabel labelSensorInfo; 
GCustomSlider csliderBrake; 
GButton buttonReverse; 
GLabel labelPowerSlider; 
GLabel labelBrakeSlider; 
GCustomSlider csliderPower; 
GLabel labelDisplay; 
GButton buttonResetPosition; 
GButton btnGenerateTrials; 
GButton btnNextTrial; 
GButton buttonSave; 
GButton btnPrevTrial; 
GButton btnSetHigh; 
GButton btnSetMedium; 
GButton btnSetBaseline; 
GButton btnBaselineTrial; 
GButton btn180Trial; 
GButton btnSet180; 

