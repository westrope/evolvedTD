// Copyright (C) 2015 evolveTD Copyright Holders

/* This is a simple class included mostly as an example of how to create box2d objects.
   It could be expanded or copied to create other box2d objects to put in the environment:
   boulders, walls, fallen trees, etc. including ones that move, rotate, are static (can't move), etc.
   */

class rock {
  Body the_rock;  // box2d body
  int radius;     // radius of the rock
  boolean remove = false;  // used to remember to remove it from the list of rocks
  PImage rockImg = null;// = loadImage("/assets/environment/rocks/rock" + (int)random(0,3) + ".png"); 
  
  rock(int x, int y) {  // Construct a rock at the given location
    radius = (int)(10);
    makebody(x, y);
    the_rock.setUserData(this);
    rockImg = loadImage("assets/environment/rocks/rock" + (int)random(0,3) + ".png");
  }
  
  rock(int x, int y, int r) {  // Construct a rock at the given location
    radius = r;
    makebody(x, y);
    the_rock.setUserData(this);
    rockImg = loadImage("assets/environment/rocks/rock" + (int)random(0,3) + ".png");
  }
  
  rock() {  // Construct a rock at a random location
    radius = (int)(10);
    makebody((int)random(-0.5*worldWidth, 0.5*worldWidth),
             (int)random(-0.5*worldHeight, 0.5*worldHeight));
    the_rock.setUserData(this);
    int rockType = (int)random(0,3); 
    rockImg = loadImage("assets/environment/rocks/rock" + (int)random(0,3) + ".png");
  }
  
  // This function removes the particle from the box2d world
  void killBody() {
    the_rock.setUserData(null);
    for (Fixture f = the_rock.getFixtureList(); f != null; f = f.getNext())
      f.setUserData(null);
    box2d.destroyBody(the_rock);
  }
  
  Vec2 getPos() {
    return(box2d.getBodyPixelCoord(the_rock));
  }
  
  int update() {
    if (remove) {
      killBody();
      return 1;
    }
    return 0;
  }
  
  void display() {  // draws the rock, could be way cooler
    Vec2 pos = box2d.getBodyPixelCoord(the_rock);
    pushMatrix();
    translate(pos.x, pos.y);
    //fill(200, 200, 200);
    //stroke(0);
    //ellipse(0, 0, radius*2, radius*2);  
    popMatrix();
    if(rockImg != null) {
      image(rockImg, pos.x - rockImg.width / 8, pos.y - rockImg.width / 8, rockImg.width / 4, rockImg.height / 4);
    }
  }
  
  void makebody(int x, int y) {
    BodyDef bd = new BodyDef();
    bd.position.set(box2d.coordPixelsToWorld(new Vec2(x, y)));
    bd.type = BodyType.DYNAMIC;
    bd.linearDamping = 0.9;
    
    the_rock = box2d.createBody(bd);
    // Define the shape -- a  (this is what we use for a rectangle)
    CircleShape sd = new CircleShape();
    sd.m_radius = box2d.scalarPixelsToWorld(radius); //radius;
    FixtureDef fd = new FixtureDef();
    fd.shape = sd;
    fd.density = 30;
    the_rock.createFixture(fd);
  }
}
