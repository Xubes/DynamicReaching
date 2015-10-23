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
static final int COMMAND_INTERVAL = 10;  // milliseconds between commands
static final int CLOCKWISE = 1, COUNTERCLOCKWISE = -1;
static final double EPS = 1e-9;
static final double CHAIR_START_SAFETY = 2.0; // chair will not spin if it's current velocity is above this value
static final double EARLY_BRAKE_THRESHOLD = 5.0; // chair will send brake command when within this many degrees of target
static final int LOW_180 = 0, LOW = 1, HIGH = 2;
int[][] settings = { {50, 0}, {50, 0}, {50, 0} };
int trialsPerBlock = 40;  // number of rotations per speed setting
Trial currentTrial;
static ArrayList<Trial> trialsRun = new ArrayList<Trial>(); // list of finished trials
static PrintWriter output;
boolean baselineFlag = false;
boolean baseline180Flag = false;
boolean experimentStarted = false;

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
  
  currentTrial = new Trial(180, LOW); // Default trial is 180 low

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
    
  StringBuilder sb = new StringBuilder();
  for(int i=0; i<settings.length; i++){
    for(int j=0; j<settings[i].length; j++){
      sb.append(settings[i][j]);
      sb.append(",");
    }
    sb.append("\n");
  }
  labelSensorInfo.setText(String.format("Position: %.3f\nDelta: %.3f\nVelocity: %.3f\n%s",anglePosition, angleDelta,angularVelocity, sb.toString()));
  
  String displayStr = String.format("Next spin: %s",(direction==1)? "CW" : "CCW");
  
  if(currentTrial!=null){
    //displayStr += String.format("\nTrial:\t%d, %d", currentTrial.degrees, currentTrial.direction);
    displayStr += "\n" + currentTrial.toString2();
  }
  else{
    displayStr += "\n" + degrees2Rotate;
  }
  
//  if(prevTrial != null){
//    displayStr += "\nPrevious spin:\n" + prevTrial.toString2();
//  }
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
  if(angularVelocity > CHAIR_START_SAFETY){ 
    System.err.println("Chair not stationary. Refusing to spin.");
    return false;
  }
  
  double prevVelocity = angularVelocity;  // use to check if accelerating
  
  // Send initial command to start moving.
//  System.err.println("Sending initial command");
  sendCommandF(command);
  
  // Wait until acceleration is detected.
//  System.err.println("Waiting for motion");
  long timeout = millis();
  while( Math.abs(angularVelocity-prevVelocity) < EPS){
    prevVelocity = angularVelocity;
    redraw();
    if(millis() - timeout > 1000){
      System.err.println("Failed to detect initial motion. Please increase power.");
      return false;
    }
  }
//  System.err.println("Got initial motion");
  
  // Re-apply power as needed.
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
  
//  System.err.println("Turning off power");
  
  // Wait until chair stops spinning AND chair has moved (to prevent early exit on short and fast spins).
  while(abs(angularVelocity) >= 2.0  || distance < 10){
    distance = abs(anglePosition-startPosition);
    // Apply brake if distance gte desire
    if(distance >= degrees-EARLY_BRAKE_THRESHOLD){
      sendCommand(0);
    }
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


/* Class to hold information about each trial.  For now the degrees turn and direction of turn. */
public class Trial{
  // Note direction is always spin direction towards target
  public int ordinal, degrees, direction, setting;
  public double speedTowards, speedReturn;  // avg speed going to and coming back from target
  public double initPosTowards, termPosTowards, initPosReturn, termPosReturn;
  public boolean complete, spinTowards;
  public int spins;  // remaining spins
  
  public Trial(int degrees, int speedSetting){
    this.degrees = degrees;
    this.setting = speedSetting;
    this.complete = false;
    degrees = (degrees==360)? 1 : 2;
    spinTowards = true;
  }
  
  public String toString(){
    return String.format("%d,%d,%d,%.3f,%.3f,%.3f,%d",
                        ordinal, degrees, direction,
                        speedTowards,initPosTowards, termPosTowards,
                        setting);
  }
  
  /* Alternate toString for the display window. */
  public String toString2(){
    return String.format("%d  %d  %d\n%.2f  %.2f  %.2f\n%d",
                          ordinal, degrees, direction,
                          speedTowards, initPosTowards, termPosTowards,
                          setting);
  }
  
  /* Return boolean variable complete. */
  public boolean isComplete(){
    return complete;
  }
  
  /* Decrement the spin counter. Set complete true if no more spins remaining. */
  public void nextSpin(){
    complete = --spins == 0;
  }
  
  /* Set data after a spin. */
  public void setResult(double initPos, double termPos, double speed){
    if(spinTowards){
      initPosTowards = initPos;
      termPosTowards = termPos;
      speedTowards = speed;
      this.direction = direction;
    }
    else{
      initPosReturn = initPos;
      termPosReturn = termPos;
      speedReturn = speed;
    }
  }
}

/* Save all the trials in trialsRun to the file. */
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
  for(Trial t : trialsRun){
    printer.println(t);
  }
  
  printer.close();
}

/* Updates the global vars to the given trial's parameters. */
public void setTrial(Trial t){
  currentTrial = t;
  //this.direction = t.direction;
  degrees2Rotate = t.degrees;
  power = settings[t.setting][0];
  brake = settings[t.setting][1];
  
  if(experimentStarted){
    currentTrial.ordinal = trialsRun.size() + 1;
  }
}

/* Generate next trial. */
public void nextTrial(){
  int nextTrialDegrees = 180, nextTrialSpeed = LOW;
  
  if(experimentStarted){
    if(currentTrial.degrees == 180){
      nextTrialDegrees = 180;
      nextTrialSpeed = LOW;
    }
    else{
      Trial prevTrial = null;
      int trs = trialsRun.size();
      if(trs > 0) prevTrial = trialsRun.get(trs -1);
      
      if(prevTrial != null){
        if(prevTrial.degrees == 180){
          // prevTrial is 180LOW and currentTrial is 360LOW
          nextTrialDegrees = 360;
          nextTrialSpeed = LOW;
        }
        else{
          // prevTrial and currentTrial 360; if prevTrial and currentTrial have matching speeds
          // use different speed. Otherwise flip coin for speed.
          if(prevTrial.setting == currentTrial.setting)
            nextTrialSpeed = (currentTrial.setting == LOW) ? HIGH : LOW;
          else
            nextTrialSpeed = (Math.random() < 0.5) ? LOW : HIGH;
            
          nextTrialDegrees = 360;
        }
      }
      else{
        // Less than 2 spins complete.
        nextTrialDegrees = 180;
        nextTrialSpeed = LOW;
      }
    }
    trialsRun.add(currentTrial);
  }
  else{
    nextTrialDegrees = (optionDegrees180.isSelected()) ? 180 : 360;
    nextTrialSpeed = (optionSpeedLow.isSelected()) ? LOW : HIGH;
  }
  
  setTrial(new Trial(nextTrialDegrees, nextTrialSpeed));
}
