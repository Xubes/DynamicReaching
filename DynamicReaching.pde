/*
Master control program for Dynamic Reaching task.  Reads sensor data from Arduino sensor
on the axel of a rotating chair and uses it to precisely rotate a the chair 180 degrees.
Each trial consists of two rotations: 180 degrees in one direction and then another in the
opposite direction to return the chair facing the starting location.
Must be able to maintain precision in 60+ trials.
*/

import processing.serial.*;

Serial serialPort;
double angleDelta;  // this will hold the angle of the chair (output from Arduino)

void setup(){
  size(300,300);
  
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
}

void draw(){
  background(255);
  fill(255,0,0);
  text(String.format("%.3f",angleDelta), 50, 50); 
}

/* Update the angle_delta global whenever a value is read from Serial port. */
void serialEvent(Serial s){
  String str = trim(s.readString());
  try{
    angleDelta = Double.parseDouble(str);
  }
  catch(NumberFormatException e){
    System.err.println("Unable to parse input : " + str);
  }
}

void keyReleased() {
}

/* Sends command to reset Arduino's angle_delta value. */
void resetAngle(){
  if(serialPort==null) return;
  serialPort.write("0\n");
}
