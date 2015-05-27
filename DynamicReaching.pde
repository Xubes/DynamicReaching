import g4p_controls.*;
import processing.serial.*;

/*
Master control program for Dynamic Reaching task.  Reads sensor data from Arduino sensor
on the axel of a rotating chair and uses it to precisely rotate a the chair 180 degrees.
Each trial consists of two rotations: 180 degrees in one direction and then another in the
opposite direction to return the chair facing the starting location.
Must be able to maintain precision in 60+ trials.
*/

Serial serialPort;
double angleDelta;  // this will hold the angle of the chair (output from Arduino)
double angularVelocity; // the angular velocity from Arduino

void setup(){
  size(300,400);
  createGUI();
  
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
  }
  
  // Set serial port to buffer until newline.
  serialPort.bufferUntil(10);
  
  angleDelta = 0.0;
  angularVelocity = 0.0;
}

void draw(){
  background(255);
  fill(255,0,0);
  txtArea.setText(String.format("%.3f\n%.3f",angleDelta,angularVelocity));
}

/* Update angleDelta and angularVelocity whenever data is available on the serial port. */
void serialEvent(Serial s){
  String str = trim(s.readString());
  String[] tokens = splitTokens(str,",");
  try{
    angleDelta = Double.parseDouble(tokens[0]);
    angularVelocity = Double.parseDouble(tokens[1]);
  }
  catch(Exception e){
    System.err.println("Unable to parse input : " + str);
  }
}

/* Sends command to reset Arduino's angle_delta value. */
void resetAngle(){
  if(serialPort==null) return;
  serialPort.write("0\n");
}

/* Get the sign of an int.  Returns one of {-1,0,1}. */
int sign(int n){
  if(n>0) return 1;
  else if(n<0) return -1;
  else return 0;
}

/* get the sign of a double. Returns one of {-1.0, 0.0, 1.0}. */
double sign(double n){
  if(n>0.0) return 1.0;
  else if(n<0.0) return -1.0;
  else return 0.0;
}
