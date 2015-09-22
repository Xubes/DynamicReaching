import g4p_controls.*;
import processing.serial.*;
import java.util.*;
import java.io.*;
/*
Master control program for Dynamic Reaching task.  Reads sensor data from Arduino sensor
on the axel of a rotating chair and uses it to precisely rotate a the chair 180 degrees.
Each trial consists of two rotations: 180 degrees in one direction and then another in the
opposite direction to return the chair facing the starting location.
Must be able to maintain precision in 60+ trials.
*/

Serial serialPort;
double anglePosition;  // angle position from Arduino
double angleDelta;  // absolute degrees rotation since last reset, from Arduino
double angularVelocity;  // velocity from Arduino
long lastCommandTime;
int lastCommand;  // store the last command sent
int power, brake, direction, degrees2Rotate;
static final int COMMAND_INTERVAL = 100;  // milliseconds between commands
static final int CLOCKWISE = 1, COUNTERCLOCKWISE = -1;
static final double EPS = 1e-9;
static final int LOW = 0, MEDIUM = 1, HIGH = 2;
int[][] settings = { {50, 0}, {50, 0}, {50, 0} };
static final int ANGLE = 360;
int trialsPerBlock = 20;  // number of rotations per speed setting
static LinkedList<Trial> trials2Run;  // list of trials
static ListIterator<Trial> li;
Trial currentTrial;
static PrintWriter output;
Trial baselineTrial, tempTrial;
boolean baselineFlag = false;

void setup(){
  size(600,400);
  createGUI();
  System.out.println("Starting...");
  
  // Look for serial port to open.
  String[] availablePorts = Serial.list();
  for(String p : availablePorts){
    if(match(p,"tty.usbmodemfa131")!=null){
      serialPort = new Serial(this, p, 115200);
    }
  }
  // Error if unable to open serial port
  if(serialPort==null){
    System.err.println("Unable to open Serial port!");
    exit();
    return;
  }
  
  // Set serial port to buffer until newline.
  serialPort.bufferUntil(10);
  
  anglePosition = 0.0;
  angleDelta = 0.0;
  angularVelocity = 0.0;
  lastCommandTime = millis();
  power = csliderPower.getValueI();
  brake = csliderBrake.getValueI();
  direction = CLOCKWISE;
  degrees2Rotate = ANGLE;
  settings[MEDIUM][0] = power;
  settings[MEDIUM][1] = brake;
  currentTrial = new Trial(ANGLE, MEDIUM);
  baselineTrial = new Trial(ANGLE, LOW);
  tempTrial = baselineTrial;
  // Open output file.
  try{
    output = new PrintWriter("DynamicReaching" + System.currentTimeMillis() + ".csv");
  }
  catch(FileNotFoundException e){
    System.err.println(e);
  }
  
  // Send shutdown commands to motor on exit.
  Thread exitHook = new Thread(){
    public void run(){
      System.out.println("-1 0 10");
      if(output!=null) output.close();
    }
  };
  Runtime.getRuntime().addShutdownHook(exitHook);
}

void draw(){
  background(255);
  fill(255,0,0);
  labelSensorInfo.setText(String.format("Position: %.3f\nDelta: %.3f\nVelocity: %.3f",anglePosition, angleDelta,angularVelocity));
  String displayStr = String.format("Next spin: %s",(direction==1)? "CW" : "CCW");
  if(currentTrial!=null){
    //displayStr += String.format("\nTrial:\t%d, %d", currentTrial.degrees, currentTrial.direction);
    displayStr += "\n" + currentTrial.toString2();
  }
  else{
    displayStr += "\n" + degrees2Rotate;
  }
  labelDisplay.setText(displayStr);
}

/* Update angleDelta and angularVelocity whenever data is available on the serial port. */
void serialEvent(Serial s){
  String str = trim(s.readString());
  String[] tokens = splitTokens(str,",");
  try{
    anglePosition = Double.parseDouble(tokens[0]);
    angleDelta = Double.parseDouble(tokens[1]);
    angularVelocity = Double.parseDouble(tokens[2]);
  }
  catch(Exception e){
    System.err.println("Unable to parse input : " + str);
  }
}

/* Sends command to reset Arduino's angle_delta value. */
void resetDelta(){
  if(serialPort==null) return;
  serialPort.write("0\n");
}

/* Sends command to reset Arduino's angle_position value. */
void resetPosition(){
  if(serialPort==null) return;
  serialPort.write("1\n");
}

/* Get the sign of an int.  Returns one of {-1,0,1}. */
int sign(int n){
  if(n>0) return 1;
  else if(n<0) return -1;
  else return 0;
}

/* Get the sign of a double. Returns one of {-1.0, 0.0, 1.0}. */
double sign(double n){
  if(n>0.0) return 1.0;
  else if(n<0.0) return -1.0;
  else return 0.0;
}

/* Spin the chair 180 degrees. Sends motor commands to standard output which should be piped
    to the actionbot program.
   Direction specifies direction of spin: positive for clockwise.
   Speed is the minimum degrees per second at which to rotate the chair. Motor power will be
   adjusted until the rotation speed equals or exceeds the given speed.
   Speed will be overridden if the desired speed cannot be achieved with the given acceleration
   for a 180 degree rotation.
 */
boolean spin180(int direction){
  return spin(180,direction);
}

/* The generalized version of spin180 for other degree settings.
    Note that there is a lower limit to the number of degrees the chair can spin.
*/
boolean spin(int degrees, int direction){
  // Command to motor; magnitude is power, sign is direction.
  int command = power*direction;
  
  // Set start position and initialize distance variable.
  double startPosition = anglePosition;
  double distance = abs(anglePosition-startPosition);
  
  // Reset total rotation counter
  resetDelta();
  
  // Do nothing if chair not stationary.  Return false.
  if(angularVelocity > 1.0){ 
    System.err.println("Chair not stationary. Refusing to spin.");
    return false;
  }
  
  double prevVelocity = angularVelocity;  // use to check if accelerating
  
  // Send initial command to start moving.
  sendCommandF(command);
  
  // Wait until acceleration is detected.
  while( Math.abs(angularVelocity-prevVelocity) < EPS){
    prevVelocity = angularVelocity;
    redraw();
  }
  
  // Re-apply power as needed until chair has rotated "almost" 180.
  // This is adjusted by the brake slider.
  while(distance < (degrees-brake)){
    distance = abs(anglePosition-startPosition);
    // just a precaution...
    if(power >= 250){
      sendCommandF(0);
      System.err.println("Motor power exceeded safe level.");
      return false;
    }
    
    // don't send a new command if chair is accelerating
    if( abs(angularVelocity-prevVelocity) > EPS){
      prevVelocity = angularVelocity;
      continue;
    }
    else{
      sendCommand(command);
    }
  }
  // Wait until chair stops spinning AND chair has moved (to prevent early exit on short and fast spins).
  while(abs(angularVelocity) >= 2.0  || distance < 10){
    distance = abs(anglePosition-startPosition);
    // Apply brake if distance gte desire
    if(distance >= degrees) sendCommand(0);
    redraw();
  }

  return true;
}

/* Format commands to std out for actionbot program.
   Keeps track of time since last command to prevent flooding the motor.
   Returns true when command written, false otherwise.
   Blocks until some time has passed.
*/
boolean sendCommand(int power){
  long now = millis();
  // make sure "enough" time has elapsed since last command time
  if( (now-lastCommandTime) > COMMAND_INTERVAL ){
    sendCommandF(power);
    return true;
  }
  return false;
}

/* Forceful version of sendCommand.  Writes command immediately. */
static final int CHAIR_MOTOR = 3;    // actionbot code for chair motor
void sendCommandF(int power){
  System.out.println(String.format("%d %d %d", CHAIR_MOTOR, power, COMMAND_INTERVAL));
  lastCommand = power;
  lastCommandTime = millis();
}

/* Absolute value function for doubles. Just calls Math.abs() */
double abs(double x){
  return Math.abs(x);
}

/* Generate trials array.  Returns a list of trial objects.
   Creates a semi-random order of trials for high and medium speed settings.
   Ensures that there are no more than two consecutive trials with the same setting.
   Prepends 4 LOW setting trials.
   Arguments:
     trialsPerSpeed : number of trials for each speed setting
     direction  : direction of spin for all trials.
   */
LinkedList<Trial> generateTrials(int trialsPerSpeed, int direction){
  LinkedList<Trial> myTrials = new LinkedList<Trial>();
  ArrayList<Integer> set = new ArrayList<Integer>();
  set.add(MEDIUM); set.add(HIGH);
  for(int i=0; i<trialsPerSpeed; i++){
    Collections.shuffle(set);
    for(int s : set){
      myTrials.add(new Trial(ANGLE, s));
    }
  }
  
  // Set ordinal for each trial (the trial number).
  int ctr = 1;
  for(Trial t : myTrials){
    t.ordinal = ctr++;
  }
  
  // Add 4 baseline (LOW) trials to the beginning.
  for(int i=0; i<4; i++){
    myTrials.addFirst(new Trial(ANGLE, LOW));
  }
  
  return myTrials;  
}

/* Class to hold information about each trial.  For now the degrees turn and direction of turn. */
public class Trial{
  public int ordinal, degrees, direction, setting;  // don't care if outside can read/write
  public double speedToward, speedReturn;  // avg speed going to and coming back from target
  public double initPosToward, termPosToward;
  public boolean complete;
  
  public Trial(int degrees, int speedSetting){
    this.degrees = degrees;
    this.setting = speedSetting;
    this.complete = false;
  }
  
  public String toString(){
    return String.format("%d,%d,%d,%.3f,%.3f,%.3f,%d",
                        ordinal, degrees, direction,
                        speedToward,initPosToward, termPosToward,
                        setting);
  }
  
  /* Alternate toString for the display window. */
  public String toString2(){
    return String.format("%d  %d  %d\n%.2f  %.2f  %.2f\n%d",
                          ordinal, degrees, direction,
                          speedToward, initPosToward, termPosToward,
                          setting);
  }
  
  /* Return boolean variable complete. */
  public boolean isComplete(){
    return complete;
  }
}

/* Save all the trials in trials2Run to the file. */
public static void saveToFile(File file){
  if (file==null){
    System.err.println("Error: invalid file selected for saving.");
    return;
  }
  // Try to open the file with a PrintWriter.
  PrintWriter printer = null;
  try{
   printer = new PrintWriter(file);
  }
  catch(FileNotFoundException e){
    System.err.println(e);
  }

  // Wite out to the file.
  for(Trial t : trials2Run){
    printer.println(t);
  }
  
  printer.close();
}

/* Updates the global vars to the given trial's parameters. */
public void setTrial(Trial t){
  this.currentTrial = t;
  //this.direction = t.direction;
  this.degrees2Rotate = t.degrees;
  this.power = settings[t.setting][0];
  this.brake = settings[t.setting][1];
}

/* Advance to next trial if available. */
public void nextTrial(){
  if(currentTrial!=null){
    output.println(currentTrial);
    if(li!=null && li.hasNext()){
      setTrial(li.next());
    }
    else{
      System.err.println("No next trial found!");
    }
  }  
}

/* Go back to previous trial if available. */
public void previousTrial(){
  if(currentTrial!=null){
    output.println(currentTrial);
    if(li!=null && li.hasPrevious()){
      setTrial(li.previous());
    }
    else{
      System.err.println("No previous trial found!");
    }
  }  
}
