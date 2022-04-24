import java.awt.Frame;
import java.awt.BorderLayout;
import javax.swing.JOptionPane;
import controlP5.*; // http://www.sojamo.de/libraries/controlP5/
import processing.serial.*;

// Colors
color bgColor = color(14, 19, 31);
color bgColor2 = color(23, 35, 54);
color fgColor = color(230, 230, 230);

color xColor = color(235, 75, 75);
color yColor = color(26, 255, 0);
color zColor = color(71, 187, 245);
color defaultColor = color(255, 184, 54);

color[] graphColors = {xColor, yColor, zColor};

// Interface
ControlP5 cp5;
PImage logo;

Graph oriGraph = new Graph(1900 - 275, 130 + 30, 260, 140, fgColor);
Graph accelGraph = new Graph(1900 - 275, 350 + 30, 260, 140, fgColor);
Graph gyroGraph = new Graph(1900 - 275, 570 + 30, 260, 140, fgColor);
Graph altitudeGraph = new Graph(1900 - 275, 790 + 30, 260, 140, fgColor);
Graph pressureGraph = new Graph(60, 165 + (3*230 + 60), 260, 90, fgColor);
Graph temperatureGraph = new Graph(60, 171 + (3*193), 260, 90, fgColor);

// Datas
int dataSeconds = 5;
int dataHz = 15;
float[] dataSamples = new float[dataSeconds * dataHz];

float[][] oriValues = new float[3][dataSamples.length];
float oriMax = 0;
float oriMin = 0;

float[][] accelValues = new float[3][dataSamples.length];
float accelMax = 0;
float accelMin = 0;

float[][] gyroValues = new float[3][dataSamples.length];
float gyroMax = 0;
float gyroMin = 0;

float[] altitudeValues = new float[dataSamples.length];
float altitudeMax = 0;
float altitudelMin = 0;

float[] pressureValues = new float[dataSamples.length];
float pressureMax = 0;
float pressureMin = 0;

float[] temperatureValues = new float[dataSamples.length];
float temperatureMax = 0;
float temperatureMin = 0;

// Current data
float oriX = 0;
float oriY = 0;
float oriZ = 0;
float accelX = 0;
float accelY = 0;
float accelZ = 0;
float gyroX = 0;
float gyroY = 0;
float gyroZ = 0;
float altitude = 0;
float rollX = 0;
float pX = 0;
float latitude = 0;
float longitude = 0;
int GPSSats = 0;
float pressure = 0;
float imuTemp = 0;
float baroTemp = 0;
float battV = 0;
int state = 0;
int cameraState = 0;
int rwState = 0;

float oldOnTimeSec = 0;
float onTimeSec = 0;
float flightTimeSec = 0;

// Data in
String COMt = "N/A";
String COMx = "N/A";
Serial inPort;

String data = "";

long nextUpdateMillis = 0;

PFont mainFont;
ControlFont buttonFont;

boolean running = true;

int buttonMargin = 190;
int buttonPadding = 30;

int buttonWidth = (1150 - (buttonPadding * 2)) / 3;
int buttonHeight = 110;

void chooseInput()
{
  COMt = COMx;
  if(inPort != null) inPort.stop();
  try {
    
    COMx = (String) JOptionPane.showInputDialog(null, 
    "Select COM Port", 
    "Select COM Port", 
    JOptionPane.QUESTION_MESSAGE, 
    null, 
    Serial.list(), 
    null
    );
     
    if (COMx == null || COMx.isEmpty()) COMx = COMt;
    
    if(COMx != "N/A")
    {
      inPort = new Serial(this, COMx, 115200); // change baud rate to your liking
      inPort.bufferUntil('\n'); // buffer until CR/LF appears, but not required..
    }
    
    nextUpdateMillis = millis();
  }
  catch (Exception e)
  { //Print the type of error
    JOptionPane.showMessageDialog(frame, "COM port " + COMx + " is not available.");
    println("Error:", e);
    COMx = "N/A";
  }
}

void enableLaunch(){
  if(!running || COMx == "N/A") return;
  if(state != 1) return;
  inPort.write("<EN>\n");
}

void advanceState(){
  if(!running || COMx == "N/A") return;
  //if(state != 1) return;
  inPort.write("<AS>\n");
}

void toggleCamera(){
  if(!running || COMx == "N/A") return;
  //if(state != 1) return;
  if(cameraState == 1){
    inPort.write("<CL>\n");
  } else {
    inPort.write("<CH>\n");
  }
}

void switchRollSetpoint(){
  if(!running || COMx == "N/A") return;
  if(state != 7) return;
  inPort.write("<SP>\n");
}

void calibrateGyros(){
  if(!running || COMx == "N/A") return;
  if(state != 1 || state != 2) return;
  inPort.write("<GY>\n");
}


void setup()
{
  surface.setTitle("RotaSat Ground Station");
  surface.setResizable(true);
  size(1920, 1080);
  
  frameRate(60);
  
  // GUI
  mainFont = createFont("Arial Bold", 27);
  buttonFont = new ControlFont(mainFont);
  
  cp5 = new ControlP5(this);
  
  cp5.addButton("chooseInput")
    .setBroadcast(false)
    .setPosition(buttonMargin + (buttonWidth + buttonPadding) * 1 -200, height - (buttonMargin + (buttonHeight + buttonPadding) * 2.5 - buttonPadding + 410))
    .setSize(buttonWidth, buttonHeight)
    .setColorBackground(color(0, 115, 255))
    .setColorForeground(color(0, 93, 207))
    .setColorActive(color(0, 93, 207))
    .setBroadcast(true)
    .setLabel("Choose Input")
    .getCaptionLabel()
    .setFont(mainFont);
  
  cp5.addButton("enableLaunch")
    .setBroadcast(false)
    .setPosition(buttonMargin + (buttonWidth + buttonPadding) * 2-200, height - (buttonMargin + (buttonHeight + buttonPadding) * 2.5 - buttonPadding+ 410))
    .setSize(buttonWidth, buttonHeight)
    .setColorBackground(color(255, 8, 8))
    .setColorForeground(color(189, 4, 4))
    .setColorActive(color(189, 4, 4))
    .setBroadcast(true)
    .setLabel("Enable Launch")
    .getCaptionLabel()
    .setFont(mainFont);
  
  cp5.addButton("toggleCamera")
    .setBroadcast(false)
    .setPosition(buttonMargin + (buttonWidth + buttonPadding) * 3-200, height - (buttonMargin + (buttonHeight + buttonPadding) * 2.5 - buttonPadding+ 410))
    .setSize(buttonWidth, buttonHeight)
    .setColorBackground(color(134, 179, 0))
    .setColorForeground(color(96, 128, 0))
    .setColorActive(color(96, 128, 0))
    .setBroadcast(true)
    .setLabel("Toggle Camera")
    .getCaptionLabel()
    .setFont(mainFont);
  
  cp5.addButton("advanceState")
    .setBroadcast(false)
    .setPosition(buttonMargin + (buttonWidth + buttonPadding) * 1-200, height - (buttonMargin + (buttonHeight + buttonPadding) * 1.5 - buttonPadding - 230))
    .setSize(buttonWidth, buttonHeight)
    .setColorBackground(color(255, 153, 51))
    .setColorForeground(color(230, 115, 0))
    .setColorActive(color(230, 115, 0))
    .setBroadcast(true)
    .setLabel("Advance State")
    .getCaptionLabel()
    .setFont(mainFont);
  
  cp5.addButton("switchRollSetpoint")
    .setBroadcast(false)
    .setPosition(buttonMargin + (buttonWidth + buttonPadding) * 2-200, height - (buttonMargin + (buttonHeight + buttonPadding) * 1.5 - buttonPadding- 230))
    .setSize(buttonWidth, buttonHeight)
    .setColorBackground(color(97, 48, 166))
    .setColorForeground(color(74, 36, 128))
    .setColorActive(color(74, 36, 128))
    .setBroadcast(true)
    .setLabel("RW Setpoint +90")
    .getCaptionLabel()
    .setFont(mainFont);
  
  cp5.addButton("calibrateGyros")
    .setBroadcast(false)
    .setPosition(buttonMargin + (buttonWidth + buttonPadding) * 3-200, height - (buttonMargin + (buttonHeight + buttonPadding) * 1.5 - buttonPadding- 230))
    .setSize(buttonWidth, buttonHeight)
    .setColorBackground(color(0, 181, 201))
    .setColorForeground(color(0, 134, 148))
    .setColorActive(color(0, 134, 148))
    .setBroadcast(true)
    .setLabel("Calibrate Gyros")
    .getCaptionLabel()
    .setFont(mainFont);
  
  logo = loadImage("logo.png");
  logo.resize(logo.width * (80 / logo.height), 80);
  
  // Graphs
  oriGraph.xLabel = "";
  oriGraph.yLabel = "";
  oriGraph.Title = "";
  oriGraph.xMin = -dataSeconds;
  oriGraph.xMax = 0;
  oriGraph.xDiv = dataSeconds;
  
  accelGraph.xLabel = "";
  accelGraph.yLabel = "";
  accelGraph.Title = "";
  accelGraph.xMin = -dataSeconds;
  accelGraph.xMax = 0;
  accelGraph.xDiv = dataSeconds;
  
  gyroGraph.xLabel = "";
  gyroGraph.yLabel = "";
  gyroGraph.Title = "";
  gyroGraph.xMin = -dataSeconds;
  gyroGraph.xMax = 0;
  gyroGraph.xDiv = dataSeconds;
  
  altitudeGraph.xLabel = "";
  altitudeGraph.yLabel = "";
  altitudeGraph.Title = "";
  altitudeGraph.xMin = -dataSeconds;
  altitudeGraph.xMax = 0;
  altitudeGraph.xDiv = dataSeconds;
  
  pressureGraph.xLabel = "";
  pressureGraph.yLabel = "";
  pressureGraph.Title = "";
  pressureGraph.xMin = -dataSeconds;
  pressureGraph.xMax = 0;
  pressureGraph.xDiv = dataSeconds;
  
  temperatureGraph.xLabel = "";
  temperatureGraph.yLabel = "";
  temperatureGraph.Title = "";
  temperatureGraph.xMin = -dataSeconds;
  temperatureGraph.xMax = 0;
  temperatureGraph.xDiv = dataSeconds;
  
  clearGraphs();
}

void draw()
{
  background(bgColor);
  
  // New data
  if(COMx != "N/A")
  {
    while(inPort.available() > 0)
    {
      char in = inPort.readChar();
      
      if(in == '\n')
      {
        if(running) parseData(data);
        data = "";
        
      }
      else
      {
        data += in;
      }
    }
  }
  checkData();
  
  image(logo, 10, 20);
  
  // Draw spacing rectangles
  stroke(fgColor);
  strokeWeight(2);
  fill(bgColor2);
  rect(logo.width + 30, -10, width + 10, 120, 10);
  for(int y = 0; y < 4; y++)
  {
    rect(width - (345), 130 + (y * 220), 320 + 20 - 1, 200 - 1, 10);
  }
  rect(10, 136 + (3*193), 320 + 20 - 1, 200 - 46, 10); //temperature
  rect(10, 130 + (3*230 + 60), 320 + 20 - 1, 200 - 46, 10); //pressure
  rect(10, 120, 320 + 20 - 1, 199/2 -5, 10); //reaction wheel
  rect(10, 130 + 160 -66, 320 + 20 - 1, 420+60, 10); //telemetry
  
  // Draw titles
  fill(fgColor);
  textSize(20);
  textAlign(CENTER, TOP);
  
  text("Orientation",    width - (340 / 2), 20 + 110 + 5);
  text("Accelerometers", width - (340 / 2), 240 + 110 + 5);
  text("Gyroscopes",     width - (340 / 2), 460 + 110 + 5);
  text("Altitude",       width - (340 / 2), 680 + 110 + 5);
  text("Ambient Pressure",       175, 680 + 150 + 10 +45);
  text("Ambient Temperature",       175, 680 + 40 +1);
  
  textSize(25);
  text("Reaction Wheel",     175, 130);
  text("Raw Telemetry Data",       175, 305 -70);
  
  textAlign(LEFT, CENTER);
  textSize(31);
  
  text("SOT: " + nf((int(onTimeSec) % 86400 ) / 3600, 2) + ":" + nf(((int(onTimeSec) % 86400 ) % 3600 ) / 60, 2) + ":" + nf(((int(onTimeSec) % 86400 ) % 3600 ) % 60, 2), 1005, 51);
  text("MET: " + nf((int(flightTimeSec) % 86400 ) / 3600, 2) + ":" + nf(((int(flightTimeSec) % 86400 ) % 3600 ) / 60, 2) + ":" + nf(((int(flightTimeSec) % 86400 ) % 3600 ) % 60, 2), 1290, 51);
  text("Date: " + nf(month(), 2) + "." + nf(day(), 2) + "." + year(), 400, 51);
  text("Local: " + nf(hour(), 2) + ":" + nf(minute(), 2) + ":" + nf(second(), 2), 720, 51);
  
  textSize(20);
  textAlign(CENTER, BOTTOM);
  
  drawState();
  
  float[] minMaxOri = minMaxValue2D(oriValues);
  oriGraph.yMin = min(minMaxOri[0], -1); // - (abs(minMaxAccel[1] - minMaxAccel[0]) / 10);
  oriGraph.yMax = max(minMaxOri[1], 1); // + (abs(minMaxAccel[1] - minMaxAccel[0]) / 10);
  
  float[] minMaxAccel = minMaxValue2D(accelValues);
  accelGraph.yMin = min(minMaxAccel[0], -1); // - (abs(minMaxAccel[1] - minMaxAccel[0]) / 10);
  accelGraph.yMax = max(minMaxAccel[1], 1); // + (abs(minMaxAccel[1] - minMaxAccel[0]) / 10);
  
  float[] minMaxGyro = minMaxValue2D(gyroValues);
  gyroGraph.yMin = min(minMaxGyro[0], -1); // - (abs(minMaxAccel[1] - minMaxAccel[0]) / 10);
  gyroGraph.yMax = max(minMaxGyro[1], 1); // + (abs(minMaxAccel[1] - minMaxAccel[0]) / 10);
  
  float[] minMaxAltitude = {min(altitudeValues), max(altitudeValues)};
  altitudeGraph.yMin = min(minMaxAltitude[0], 0); // - (abs(minMaxAccel[1] - minMaxAccel[0]) / 10);
  altitudeGraph.yMax = max(minMaxAltitude[1], 1); // + (abs(minMaxAccel[1] - minMaxAccel[0]) / 10);
  
  float[] minMaxPressure = {min(pressureValues), max(pressureValues)};
  pressureGraph.yMin = min(minMaxPressure[0], -1); // - (abs(minMaxAccel[1] - minMaxAccel[0]) / 10);
  pressureGraph.yMax = max(minMaxPressure[1], 1); // + (abs(minMaxAccel[1] - minMaxAccel[0]) / 10);
 
  float[] minMaxTemperature = {min(temperatureValues), max(temperatureValues)};
  temperatureGraph.yMin = min(minMaxTemperature[0], -1); // - (abs(minMaxAccel[1] - minMaxAccel[0]) / 10);
  temperatureGraph.yMax = max(minMaxTemperature[1], 1); // + (abs(minMaxAccel[1] - minMaxAccel[0]) / 10);
  
  oriGraph.DrawAxis();
  accelGraph.DrawAxis();
  gyroGraph.DrawAxis();
  altitudeGraph.DrawAxis();
  pressureGraph.DrawAxis();
  temperatureGraph.DrawAxis();
  for(int i = 0; i < 3; i++)
  {
    oriGraph.GraphColor = graphColors[i];
    accelGraph.GraphColor = graphColors[i];
    gyroGraph.GraphColor = graphColors[i];
    
    oriGraph.LineGraph(dataSamples, oriValues[i]);
    accelGraph.LineGraph(dataSamples, accelValues[i]);
    gyroGraph.LineGraph(dataSamples, gyroValues[i]);
  }
  altitudeGraph.GraphColor = defaultColor;
  altitudeGraph.LineGraph(dataSamples, altitudeValues);
  pressureGraph.GraphColor = defaultColor;
  pressureGraph.LineGraph(dataSamples, pressureValues);
  temperatureGraph.GraphColor = defaultColor;
  temperatureGraph.LineGraph(dataSamples, pressureValues);
  // Raw telem values
  noStroke();
  fill(fgColor);
  textAlign(LEFT, CENTER);
  textSize(15);
  text("oX:  " + nf(oriX, 0, 2), 40, 360 -73);
  text("oY:  " + nf(oriY, 0, 2), 40, 390 -73);
  text("oZ:  " + nf(oriZ, 0, 2), 40, 420 -73);
  
  text("aX:  " + nf(accelX, 0, 2), 40, 450 -73);
  text("aY:  " + nf(accelY, 0, 2), 40, 480 -73);
  text("aZ:  " + nf(accelZ, 0, 2), 40, 510 -73);
  
  text("gX:  " + nf(gyroX, 0, 2), 40, 540 -73);
  text("gY:  " + nf(gyroY, 0, 2), 40, 570 -73);
  text("gZ:  " + nf(gyroZ, 0, 2), 40, 600 -73);
  
  text("pX:  " + nf(pX, 0, 2), 40, 630 -73);
  text("GPS Sats:  " + nf(GPSSats, 0, 0), 40, 690 -73);
  text("lat:  " + nf(latitude, 0, 5), 40, 660 -73);
  text("lon:  " + nf(longitude, 0, 5), 200, 660 -73);
  text("alt:  " + nf(altitude, 0, 2), 200, 630 -73);
  
  text("p:  " + nf(pressure, 0, 2), 200, 600 -73);
  
  text("IMU T:  " + nf(imuTemp, 0, 2), 200, 570 -73);
  text("baro T:  " + nf(baroTemp, 0, 2), 200, 540 -73);
    
  text("state:  " + state, 200, 360 -73);
  text("cameraState:  " + cameraState, 200, 390 -73);
  text("rwState:  " + rwState, 200, 420 -73);
  text("volts:  " + nf(battV, 0, 2), 200, 450 -73);
  
  if((oldOnTimeSec - onTimeSec) == 0){
    text("TLM:  " + nf(0, 0, 2), 200, 480 -73);
  } else {
    text("TLM:  " + nf(1 / (onTimeSec - oldOnTimeSec), 0, 2), 200, 480 -73);
  }
  
  text("TLM Δ:  " + nf(onTimeSec - oldOnTimeSec, 0, 3), 200, 510 -73);
   
  textAlign(RIGHT, CENTER);
  text("°", 170, 360 -73);
  text("°", 170, 390 -73);
  text("°", 170, 420 -73);
  text("m/s²", 170, 450 -73);
  text("m/s²", 170, 480 -73);
  text("m/s²", 170, 510 -73);
  text("°/s", 170, 540 -73);
  text("°/s", 170, 570 -73);
  text("°/s", 170, 600 -73);
  text("m", 330, 630 -73);
  text("m", 170, 630 -73);
  text("hPa", 330, 600 -73);
  text("°C", 330, 570 -73);
  text("°C", 330, 540 -73);
  
  text("V", 330, 450 -73);
  text("Hz", 330, 480 -73);
  text("s", 330, 510 -73);
  
  text("°", 170, 660 -73);
  text("°", 330, 660 -73);
  textAlign(LEFT, CENTER);
  textSize(18);
  
  text("RW Enabled: " + nf(rwState, 0), 200, 185);
  text("RW Signal: " + nf(rollX, 0, 2), 40, 185);
}

void drawState()
{
  color stateColor;
  String stateString;
  
  switch(state)
  {
    case 1:
      stateColor = color(68, 184, 81);
      stateString = "Ground Idle";
      break;
    case 2:
      stateColor = color(242, 140, 51);
     stateString = "Ready for Launch";
      break;
    case 3:
      stateColor = color(9, 183, 222);
      stateString = "Powered Ascent";
      break;
    case 4:
      stateColor = color(190, 109, 207);
      stateString = "Unpowered Ascent";
      break;
    case 5:
      stateColor = color(230, 222, 7);
      stateString = "Launch Vehicle Sep";
      break;
    case 6:
      stateColor = color(16, 224, 214);
      stateString = "Parachute Descent";
      break;
    case 7:
      stateColor = color(68, 184, 81);
      stateString = "Roll Ori Control";
      break;
    case 8:
      stateColor = color(68, 184, 81);
      stateString = "Under 50m (RW Off)";
      break;
    case 9:
      stateColor = color(68, 184, 81);
      stateString = "Mission Complete";
      break;
    default:
      stateColor = color(217, 15, 15);
      stateString = "Invalid State";
      break;
  }
  
  fill(stateColor);
  noStroke();
  textAlign(CENTER, CENTER);
  rect(width - 315 - 10, 20, 300, 70, 10);
  textSize(30);
  fill(255);
  text(stateString, width - 165 - 10, 51);
}

float[] minMaxValue2D(float[][] input)
{
  float[] minMax = {0, 0};
  
  for(int i = 0; i < input.length; i++)
  {
    for(int j = 0; j < input[i].length; j++)
    {
      minMax[0] = min(minMax[0], input[i][j]);
      minMax[1] = max(minMax[1], input[i][j]);
    }
  }
  
  return minMax;
}

void checkData()
{
  if(!running || COMx == "N/A") return;
  if(millis() > nextUpdateMillis)
  {
    // Rotate arrays
    for(int j = 0; j < 3; j++)
    {
      for(int i = 0; i < dataSamples.length - 1; i++)
      {
        oriValues[j][i] = oriValues[j][i + 1];
        accelValues[j][i] = accelValues[j][i + 1];
        gyroValues[j][i] = gyroValues[j][i + 1];
        if(j == 0) // Hacky way to do this once
        {
          altitudeValues[i] = altitudeValues[i + 1];
          pressureValues[i] = pressureValues[i + 1];
        }
      }
    }
    
    oriValues[0][dataSamples.length - 1] = oriX;
    oriValues[1][dataSamples.length - 1] = oriY;
    oriValues[2][dataSamples.length - 1] = oriZ;
    
    accelValues[0][dataSamples.length - 1] = accelX;
    accelValues[1][dataSamples.length - 1] = accelY;
    accelValues[2][dataSamples.length - 1] = accelZ;
    
    gyroValues[0][dataSamples.length - 1] = gyroX;
    gyroValues[1][dataSamples.length - 1] = gyroY;
    gyroValues[2][dataSamples.length - 1] = gyroZ;
    
    altitudeValues[dataSamples.length - 1] = altitude;
    pressureValues[dataSamples.length - 1] = pressure;
    
    nextUpdateMillis += 1000 / dataHz;
  }
}

int parseData(String data)
{
  // Check data is good
  if(data.length() == 0) return -1;
  if(data.charAt(0) != 'R' || data.charAt(1) != 'O' || data.charAt(2) != 'T' || data.charAt(3) != 'A'|| data.charAt(4) != 'T' || data.charAt(5) != 'L' || data.charAt(6) != 'M') return -1;

  String[] dataBits = split(data.substring(7), ',');

  if(dataBits.length != 24) return -1;
  
  oldOnTimeSec = onTimeSec;

  oriX = parseFloat(dataBits[0]);
  oriY = parseFloat(dataBits[1]);
  oriZ = parseFloat(dataBits[2]);
  accelX = parseFloat(dataBits[3]);
  accelY = parseFloat(dataBits[4]);
  accelZ = parseFloat(dataBits[5]);
  gyroX = parseFloat(dataBits[6]);
  gyroY = parseFloat(dataBits[7]);
  gyroZ = parseFloat(dataBits[8]);
  altitude = parseFloat(dataBits[9]);
  pX = parseFloat(dataBits[10]);
  rollX = parseFloat(dataBits[11]);
  battV = parseFloat(dataBits[12]);
  state = parseInt(dataBits[13]);
  cameraState = parseInt(dataBits[14]);
  rwState = parseInt(dataBits[15]);
  onTimeSec = parseFloat(dataBits[16]);
  flightTimeSec = parseFloat(dataBits[17]);
  pressure = parseFloat(dataBits[18]);
  imuTemp = parseFloat(dataBits[19]);
  baroTemp = parseFloat(dataBits[20]);
  GPSSats = parseInt(dataBits[21]);
  latitude = parseFloat(dataBits[22]);
  longitude = parseFloat(dataBits[23]);
  return 0;
}

void startSerial()
{
  if(COMx != "N/A")
  {
    running = true;
    nextUpdateMillis = millis();
  }
}

void clearGraphs()
{
  for(int i = 0; i < dataSamples.length; i++)
  {
    dataSamples[i] = ((float)i / dataHz);
    
    for(int j = 0; j < 3; j++)
    {
      oriValues[j][i] = 0;
      accelValues[j][i] = 0;
      gyroValues[j][i] = 0;
    }
    
    altitudeValues[i] = 0;
    pressureValues[i] = 0;
  }
}
