// //<>// //<>// //<>// //<>// //<>// //<>//
//  Animator.pde
//  Lightwork-Mapper
//
//  Created by Leo Stefansson and Tim Rolls
//
//  This Class handles timing and generates the state and color of all connected LEDs
//  Currently missing Binary pattern parts
//
//////////////////////////////////////////////////////////////


enum animationMode {
  CHASE, TEST, BINARY, OFF
};

public class Animator {

  int                 ledIndex;               // Index of LED being mapped (lit and detected).
  int                 numLedsPerStrip;        // Number of LEDs per strip
  int                 numStrips;              // How many strips total
  int                 ledBrightness;          // Brightness of LED's in the animation sequence. Currently hard-coded but
  // will be determined by camera frame brightness (to avoid flaring by
  // excessively bright LEDs).

  int                 testIndex;              // Used for the test() animation sequence
  int                 frameCounter;           // Internal framecounter
  int                 frameSkip;              // How many frames to skip between updates

  animationMode       mode;

  Animator() {
    println("Animator created");
    ledIndex = 0; // Internal counter
    mode = animationMode.OFF;

    testIndex = 0;
    frameCounter = 0;
    frameSkip = 3;
  }

  //////////////////////////////////////////////////////////////
  // Setters and getters
  //////////////////////////////////////////////////////////////


  void setMode(animationMode m) {
    setAllLEDColours(off);
    mode = m;
    ledIndex = 0; // TODO: resetInternalVariables() method?
    testIndex = 0;
    frameCounter = 0;
    resetPixels();
  }

  animationMode getMode() {
    return mode;
  }

  void setLedBrightness(int brightness) { //TODO: set overall brightness?
    ledBrightness = brightness;
    //opcClient->autoWriteData(getPixels());
  }

  void setFrameSkip(int num) {
    frameSkip = num;
  }

  int getFrameSkip() {
    return frameSkip;
  }

  // Internal method to reassign pixels with a vector of the right length. Gives all pixels a value of (0,0,0) (black/off).
  void resetPixels() {
    network.populateLeds();
    network.update(this.getPixels());
  }

  // Return pixels (to update OPC or PixelPusher) --Changed to array, arraylist wasn't working on return
  color[] getPixels() {
    color[] l = new color[leds.size()];
    for (int i = 0; i<leds.size(); i++) {
      l[i]=leds.get(i).c;
    }
    return l;
  }


  //////////////////////////////////////////////////////////////
  // Animation Methods
  //////////////////////////////////////////////////////////////

  void update() {
    //if (frameCount % frameSkip == 0) { //<>// //<>//
    switch(mode) {
    case CHASE: 
      {
        chase();
        break;
      }
    case TEST: 
      {
        test();
        break;
      }
    case BINARY: 
      {
        binaryAnimation();
        break;
      }

    case OFF: 
      {
      }
    };

    // Advance the internal counter
    frameCounter++;

    //send pixel data over network
    if (mode!=animationMode.OFF && network.isConnected) {
      network.update(this.getPixels());
    }

    // draw LED color array to screen -
    for (int i = 0; i<leds.size(); i++) {
      fill(leds.get(i).c);
      noStroke();
      rect(i*5, (height)-5, 5, 5);
    }
  }

  // Update the pixels for all the strips
  // This method does not return the pixels, it's up to the users to send animator.pixels to the driver (FadeCandy, PixelPusher).
  void chase() {
    for (int i = 0; i <  leds.size(); i++) {
      color col;
      if (i == ledIndex) {
        col = color(ledBrightness, ledBrightness, ledBrightness);
      } else {
        col = color(0, 0, 0);
      }
      leds.get(i).setColor(col);
    }

    if (frameCounter%frameSkip==0)ledIndex++; // use frameskip to delay animation updates

    // Loop around
    if (ledIndex >= leds.size()) {
      ledIndex = 0;
    }
  }

  // Set all LEDs to the same colour (useful to turn them all on or off).
  void setAllLEDColours(color col) {
    for (int i = 0; i <  leds.size(); i++) { //<>//
      leds.get(i).setColor(col);
    }
  }

  //LED Pre-flight test
  void test() {
    testIndex++;

    if (testIndex < 30) {
      setAllLEDColours(color(255, 0, 0));
    } else if (testIndex > 30 && testIndex < 60) {
      setAllLEDColours(color(0, 255, 0));
    } else if (testIndex > 60 && testIndex < 90) {
      setAllLEDColours(color(0, 0, 255));
    }

    if (testIndex > 90) {
      testIndex = 0;
    }
  }

  void binaryAnimation() {
    if (frameCounter%frameSkip==0) {
      for (int i = 0; i <  leds.size(); i++) {
      leds.get(i).binaryPattern.advance();
      
      switch(leds.get(i).binaryPattern.state) {
      case 0:
        leds.get(i).setColor(color(0, 0, 0));
        break;
      case 1:
        leds.get(i).setColor(color(ledBrightness, ledBrightness, ledBrightness));
        break;
      }
    }
    }
    
  }
}