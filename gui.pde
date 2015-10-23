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
//  println("btnResetDelta - GButton >> GEvent." + event + " @ " + millis());
  resetDelta();
} //_CODE_:btnResetDelta:933479:

public void btnSpinClick(GButton source, GEvent event) { //_CODE_:btnSpin:521123:
//  println("btnSpin - GButton >> GEvent." + event + " @ " + millis());
  source.setEnabled(false);
  
  if(experimentStarted){
    setTrial(currentTrial);
  }
  
  resetPosition();
  
  long startTime = millis();
  while(millis()-startTime<100){}; // busy wait 100 millis to let sensor update
  
  System.err.println("Spinning");
  
  double startPosition = anglePosition;
  startTime = millis();
  if(spin(degrees2Rotate,direction)){
    double endPosition = anglePosition;
    double stopTime = millis();
    double avgVelocity = 1000 * Math.abs( (endPosition-startPosition)/(stopTime-startTime));
    
    currentTrial.setResult(startPosition, endPosition, avgVelocity);
    currentTrial.nextSpin();
    
    direction *= -1;  // next spin will go in opposite direction
    
    if(currentTrial.isComplete()){
      nextTrial();
    }
  }
  else{
    System.err.println("Something happened! Failed to spin!");
  }
  
  System.err.println("Done spinning.");
  source.setEnabled(true);
} //_CODE_:btnSpin:521123:

public void csliderBrakeChange(GCustomSlider source, GEvent event) { //_CODE_:csliderBrake:657048:
//  println("csliderBrake - GCustomSlider >> GEvent." + event + " @ " + millis());
  brake = source.getValueI();
} //_CODE_:csliderBrake:657048:

public void buttonReverseClick(GButton source, GEvent event) { //_CODE_:buttonReverse:305135:
//  println("buttonReverse - GButton >> GEvent." + event + " @ " + millis());
  direction *= -1;
} //_CODE_:buttonReverse:305135:

public void csliderPowerChange(GCustomSlider source, GEvent event) { //_CODE_:csliderPower:301311:
//  println("csliderPower - GCustomSlider >> GEvent." + event + " @ " + millis());
  power = source.getValueI();
} //_CODE_:csliderPower:301311:

public void buttonResetPositionClick(GButton source, GEvent event) { //_CODE_:buttonResetPosition:614711:
//  println("buttonResetPosition - GButton >> GEvent." + event + " @ " + millis());
  resetPosition();
} //_CODE_:buttonResetPosition:614711:

public void btnStartExperimentClicked(GButton source, GEvent event) { //_CODE_:btnStartExperiment:224544:
//  println("btnStartExperiment - GButton >> GEvent." + event + " @ " + millis());
  experimentStarted = true;
  optionSpeedLow.setEnabled(false);
  optionSpeedHigh.setEnabled(false);
//  togGroupSpeed.setEnabled(false);
} //_CODE_:btnStartExperiment:224544:

public void buttonSaveClick(GButton source, GEvent event) { //_CODE_:buttonSave:860221:
//  println("buttonSave - GButton >> GEvent." + event + " @ " + millis());
    selectOutput("Select file to save to.", "saveToFile");
} //_CODE_:buttonSave:860221:

public void btnSetHighClick(GButton source, GEvent event) { //_CODE_:btnSetHigh:288642:
//  println("btnSetHigh - GButton >> GEvent." + event + " @ " + millis());
  settings[HIGH][0] = power;
  settings[HIGH][1] = brake;
} //_CODE_:btnSetHigh:288642:

public void btnSetBaselineClick(GButton source, GEvent event) { //_CODE_:btnSetBaseline:335533:
//  println("btnSetBaseline - GButton >> GEvent." + event + " @ " + millis());
  settings[LOW][0] = power;
  settings[LOW][1] = brake;
} //_CODE_:btnSetBaseline:335533:

public void btnSet180Click(GButton source, GEvent event) { //_CODE_:btnSet180:750451:
//  println("btnSet180 - GButton >> GEvent." + event + " @ " + millis());
  settings[LOW_180][0] = power;
  settings[LOW_180][1] = brake;
} //_CODE_:btnSet180:750451:

public void optionDegrees180_clicked1(GOption source, GEvent event) { //_CODE_:optionDegrees180:910358:
//  println("optionDegree180 - GOption >> GEvent." + event + " @ " + millis());
  currentTrial.degrees = 180;
  setTrial(currentTrial);
} //_CODE_:optionDegrees180:910358:

public void optionDegrees360_clicked1(GOption source, GEvent event) { //_CODE_:optionDegrees360:996744:
//  println("optionDegree360 - GOption >> GEvent." + event + " @ " + millis());
  currentTrial.degrees = 360;
  setTrial(currentTrial);
} //_CODE_:optionDegrees360:996744:

public void optionSpeedBaseline_clicked1(GOption source, GEvent event) { //_CODE_:optionSpeedLow:932526:
//  println("optionSpeedBaseline - GOption >> GEvent." + event + " @ " + millis());
  currentTrial.setting = (currentTrial.degrees == 360) ? LOW : LOW_180;
  setTrial(currentTrial);
} //_CODE_:optionSpeedLow:932526:

public void optionSpeedHigh_clicked1(GOption source, GEvent event) { //_CODE_:optionSpeedHigh:312837:
//  println("optionSpeedHigh - GOption >> GEvent." + event + " @ " + millis());
  currentTrial.setting = HIGH;
  setTrial(currentTrial);
} //_CODE_:optionSpeedHigh:312837:



// Create all the GUI controls. 
// autogenerated do not edit
public void createGUI(){
  G4P.messagesEnabled(false);
  G4P.setGlobalColorScheme(GCScheme.BLUE_SCHEME);
  G4P.setCursor(ARROW);
  if(frame != null)
    frame.setTitle("Sketch Window");
  btnResetDelta = new GButton(this, 190, 20, 110, 50);
  btnResetDelta.setText("Reset Delta");
  btnResetDelta.setLocalColorScheme(GCScheme.PURPLE_SCHEME);
  btnResetDelta.addEventHandler(this, "btnResetDeltaClick");
  btnSpin = new GButton(this, 110, 330, 140, 50);
  btnSpin.setText("Spin!");
  btnSpin.setTextBold();
  btnSpin.setLocalColorScheme(GCScheme.GREEN_SCHEME);
  btnSpin.addEventHandler(this, "btnSpinClick");
  labelSensorInfo = new GLabel(this, 40, 80, 260, 120);
  labelSensorInfo.setOpaque(true);
  csliderBrake = new GCustomSlider(this, 470, 20, 280, 70, "red_yellow18px");
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
  labelPowerSlider = new GLabel(this, 320, 300, 70, 20);
  labelPowerSlider.setText("Power");
  labelPowerSlider.setTextBold();
  labelPowerSlider.setLocalColorScheme(GCScheme.GREEN_SCHEME);
  labelPowerSlider.setOpaque(true);
  labelBrakeSlider = new GLabel(this, 400, 300, 70, 20);
  labelBrakeSlider.setText("Brake");
  labelBrakeSlider.setTextBold();
  labelBrakeSlider.setLocalColorScheme(GCScheme.ORANGE_SCHEME);
  labelBrakeSlider.setOpaque(true);
  csliderPower = new GCustomSlider(this, 390, 20, 280, 70, "blue18px");
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
  labelDisplay = new GLabel(this, 40, 210, 260, 110);
  labelDisplay.setText("Hi.");
  labelDisplay.setTextBold();
  labelDisplay.setLocalColorScheme(GCScheme.PURPLE_SCHEME);
  labelDisplay.setOpaque(true);
  buttonResetPosition = new GButton(this, 40, 20, 100, 50);
  buttonResetPosition.setText("Reset Position");
  buttonResetPosition.addEventHandler(this, "buttonResetPositionClick");
  btnStartExperiment = new GButton(this, 480, 190, 100, 50);
  btnStartExperiment.setText("Start Experiment");
  btnStartExperiment.setTextBold();
  btnStartExperiment.setLocalColorScheme(GCScheme.ORANGE_SCHEME);
  btnStartExperiment.addEventHandler(this, "btnStartExperimentClicked");
  buttonSave = new GButton(this, 480, 250, 100, 50);
  buttonSave.setText("Save");
  buttonSave.setTextBold();
  buttonSave.setLocalColorScheme(GCScheme.CYAN_SCHEME);
  buttonSave.addEventHandler(this, "buttonSaveClick");
  btnSetHigh = new GButton(this, 480, 20, 100, 40);
  btnSetHigh.setText("Set High");
  btnSetHigh.setTextBold();
  btnSetHigh.setLocalColorScheme(GCScheme.RED_SCHEME);
  btnSetHigh.addEventHandler(this, "btnSetHighClick");
  btnSetBaseline = new GButton(this, 480, 70, 100, 40);
  btnSetBaseline.setText("Set Baseline");
  btnSetBaseline.setTextBold();
  btnSetBaseline.setLocalColorScheme(GCScheme.GREEN_SCHEME);
  btnSetBaseline.addEventHandler(this, "btnSetBaselineClick");
  btnSet180 = new GButton(this, 480, 120, 100, 40);
  btnSet180.setText("Set 180");
  btnSet180.setTextBold();
  btnSet180.setLocalColorScheme(GCScheme.PURPLE_SCHEME);
  btnSet180.addEventHandler(this, "btnSet180Click");
  togGroupDegrees = new GToggleGroup();
  optionDegrees180 = new GOption(this, 290, 340, 50, 40);
  optionDegrees180.setTextAlign(GAlign.LEFT, GAlign.MIDDLE);
  optionDegrees180.setText("180");
  optionDegrees180.setTextBold();
  optionDegrees180.setLocalColorScheme(GCScheme.PURPLE_SCHEME);
  optionDegrees180.setOpaque(true);
  optionDegrees180.addEventHandler(this, "optionDegrees180_clicked1");
  optionDegrees360 = new GOption(this, 350, 340, 50, 40);
  optionDegrees360.setTextAlign(GAlign.LEFT, GAlign.MIDDLE);
  optionDegrees360.setText("360");
  optionDegrees360.setTextBold();
  optionDegrees360.setOpaque(true);
  optionDegrees360.addEventHandler(this, "optionDegrees360_clicked1");
  togGroupDegrees.addControl(optionDegrees180);
  optionDegrees180.setSelected(true);
  togGroupDegrees.addControl(optionDegrees360);
  togGroupSpeed = new GToggleGroup();
  optionSpeedLow = new GOption(this, 430, 330, 70, 50);
  optionSpeedLow.setTextAlign(GAlign.LEFT, GAlign.MIDDLE);
  optionSpeedLow.setText("Baseline");
  optionSpeedLow.setTextBold();
  optionSpeedLow.setLocalColorScheme(GCScheme.GREEN_SCHEME);
  optionSpeedLow.setOpaque(true);
  optionSpeedLow.addEventHandler(this, "optionSpeedBaseline_clicked1");
  optionSpeedHigh = new GOption(this, 520, 330, 70, 50);
  optionSpeedHigh.setTextAlign(GAlign.LEFT, GAlign.MIDDLE);
  optionSpeedHigh.setText("High");
  optionSpeedHigh.setTextBold();
  optionSpeedHigh.setLocalColorScheme(GCScheme.RED_SCHEME);
  optionSpeedHigh.setOpaque(true);
  optionSpeedHigh.addEventHandler(this, "optionSpeedHigh_clicked1");
  togGroupSpeed.addControl(optionSpeedLow);
  optionSpeedLow.setSelected(true);
  togGroupSpeed.addControl(optionSpeedHigh);
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
GButton btnStartExperiment; 
GButton buttonSave; 
GButton btnSetHigh; 
GButton btnSetBaseline; 
GButton btnSet180; 
GToggleGroup togGroupDegrees; 
GOption optionDegrees180; 
GOption optionDegrees360; 
GToggleGroup togGroupSpeed; 
GOption optionSpeedLow; 
GOption optionSpeedHigh; 

