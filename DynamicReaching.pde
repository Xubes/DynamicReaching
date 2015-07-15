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
int BASELINE = 180, OVERSHOOT = 240, UNDERSHOOT = 110;
int[] angles = {BASELINE, UNDERSHOOT, OVERSHOOT};  // degrees to use for generating trials
int trialsPerBlock = 8;  // number of rotations (each direction) per block
LinkedList<Trial> trials2Run;  // list of trials
ListIterator<Trial> li;
Trial currentTrial;
static PrintWriter output;

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
  degrees2Rotate = angles[0];
  currentTrial = new Trial(degrees2Rotate, direction);
  try{
    output = new PrintWriter("DynamicReaching.txt");
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
    displayStr += "\n" + currentTrial;
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
    if(power >= 150){
      sendCommandF(0);
      System.err.println("Motor power exceeded safe level.");
      return false;
    }
    
    // don't send a new command if chair is accelerating
    if( (angularVelocity-prevVelocity) > EPS){
      prevVelocity = angularVelocity;
      continue;
    }
    else{
      sendCommand(command);
    }
  }
  // send brake command
  //sendCommand(0);
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
   Args: angles - the list of angles; trials - the number of trials in each direction per angle. 
   */
LinkedList<Trial> generateTrials(int angles[], int trials){
  LinkedList<Trial> myTrials = new LinkedList<Trial>();

  for(int angle : angles){
    for(int i=0; i<trials; i++){
      myTrials.add(new Trial(angle, CLOCKWISE));
      myTrials.add(new Trial(angle, COUNTERCLOCKWISE));
    }
  }
  
  Collections.shuffle(myTrials);
  Collections.shuffle(myTrials);
  
  // Set ordinal for each trial (the trial number).
  int ctr = 1;
  for(Trial t : myTrials){
    t.ordinal = ctr++;
  }
  return myTrials;  
}

/* Class to hold information about each trial.  For now the degrees turn and direction of turn. */
public class Trial{
  public int ordinal, degrees, direction;  // don't care if outside can read/write
  public double speedToward, speedReturn;  // avg speed going to and coming back from target
  
  public Trial(int degrees, int direction){
    this.degrees = degrees;
    this.direction = direction;
  }
  
  public String toString(){
    return String.format("%d,%d,%d,%.3f,%.3f", ordinal, degrees, direction, speedToward, speedReturn);
  }
}
