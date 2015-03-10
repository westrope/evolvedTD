static int creature_count = 0;

class creature {
  // stats
  int num;               // unique creature identifier
  boolean alive;         // dead creatures remain in the swarm to have a breeding chance
  float fitness;         // used for selection
  float health;          // 0 health, creature dies
  float maxHealth = 100; // TODO: should be evolved
  int health_regen = 1;  // value to set how much health is regenerated each timestep when energy is spent to regen
  int round_counter;     // counter to track how many rounds/generations the individual creature has been alive

  // timers
  int timestep_counter;  // counter to track how many timesteps a creature has been alive
  int time_in_water;     // tracks how much time the creature spends in water
  int time_on_land;      // tracks how much time the creature spends on land

  // encodes the creature's genetic information
  Genome genome;
  Brain brain;
  float current_actions[];

  // metabolism
  float energy_reproduction;     // energy for gamete produciton
  float energy_locomotion;       // energy for locomotion and similar activites
  float energy_health;           // energy for regeneration
  float max_energy_reproduction; // size of reproductive energy stores
  float max_energy_locomotion;
  float max_energy_health;
  int regen_energy_cost = 5; // value to determine how much regenerating health costs
  metabolic_network metabolism;

  // senses/communication
  Sensory_Systems senses;
  boolean scent;       // used to determine if creature is capable of producing scent
  float scentStrength; // how strong the creature's scent is
  int scentColor;      // store an integer for different colors

  // body
  Body body;
  float angle;
  int numSegments;
  FloatList armor;
  float density;
  color_network coloration;

  // Constructor, creates a new creature at the given location and angle

  // This constructor is generally only used for the first wave, after
  // that creatures are created from parents.
  creature(float x, float y, float a) {
    num = creature_count++;
    angle = a;
    
    genome = new Genome();
    senses = new Sensory_Systems(genome);
    brain = new Brain(genome);
    current_actions = new float[brain.OUTPUTS];
    
    numSegments = getNumSegments();
    computeArmor();
    float averageArmor = armor.sum() / numSegments;
    density = (getDensity() * averageArmor);
    makeBody(new Vec2(x, y));   // call the function that makes a Box2D body
    body.setUserData(this);     // required by Box2D
    float energy_scale = 500; // scales the max energy pool size
    float max_sum = abs(genome.sum(maxReproductiveEnergy)) + abs(genome.sum(maxLocomotionEnergy)) + abs(genome.sum(maxHealthEnergy));
    max_energy_reproduction = body.getMass() * energy_scale * abs(genome.sum(maxReproductiveEnergy))/max_sum; // initial mass is around 150, so factor of 1000 gives reasonable energy storage.
    max_energy_locomotion = body.getMass() * energy_scale * abs(genome.sum(maxLocomotionEnergy))/max_sum;
    max_energy_health =  body.getMass() * energy_scale * abs(genome.sum(maxHealthEnergy))/max_sum;
    energy_reproduction = 0;    // have to collect energy to reproduce
    energy_locomotion = min(20000,max_energy_locomotion);  // start with energy for locomotion, the starting amount should come from the gamete and should be evolved
    energy_health = 0;          // have to collect energy to regenerate, later this may be evolved
    //println(max_energy_reproduction + " " + max_energy_locomotion + ":" +energy_locomotion + " "+ max_energy_health);  // for debugging
    metabolism = new metabolic_network(genome);
    coloration = new color_network(genome);
    health = maxHealth;         // initial health
    fitness = 0;                // initial fitness
    alive = true;               // creatures begin life alive

    scent = setScent(this);     // does creature produce scent
    scentStrength = setScentStrength(this);        // how strong is the scent
    scentColor = setScentColor(this); // what color is the scent

  }

  // construct a new creature with the given genome and energy
  creature(Genome g, float e) {
    num = creature_count++;
    angle = random(0, 2 * PI); // start at a random angle
    genome = g;
    senses = new Sensory_Systems(genome);
    numSegments = getNumSegments();
    computeArmor();
    float averageArmor = armor.sum() / numSegments;
    density = (getDensity() * averageArmor);

    // Currently creatures are 'born' around a circle a fixed distance
    // from the tower. Birth locations should probably be evolved as
    // part of the reproductive strategy and/or behavior
    Vec2 pos = new Vec2(0.45 * worldWidth * sin(angle),
                        0.45 * worldWidth * cos(angle));
    makeBody(pos);
    float energy_scale = 500;
    float max_sum = abs(genome.sum(maxReproductiveEnergy)) + abs(genome.sum(maxLocomotionEnergy)) + abs(genome.sum(maxHealthEnergy));
    max_energy_reproduction = body.getMass() * energy_scale * abs(genome.sum(maxReproductiveEnergy))/max_sum;
    max_energy_locomotion = body.getMass() * energy_scale * abs(genome.sum(maxLocomotionEnergy))/max_sum;
    max_energy_health =  body.getMass() * energy_scale * abs(genome.sum(maxHealthEnergy))/max_sum;
    energy_reproduction = 0;                                // have to collect energy to reproduce
    energy_locomotion = min(e,max_energy_locomotion);       // start with energy for locomotion, the starting amount should come from the gamete and should be evolved
    energy_health = 0;                                      // have to collect energy to regenerate, later this may be evolved
    metabolism = new metabolic_network(genome);
    coloration = new color_network(genome);
    health = maxHealth;                                     // probably should be evolved
    fitness = 0;
    body.setUserData(this);
    alive = true;

    scent = setScent(this);                 // does creature produce scent
    scentStrength = setScentStrength(this); // how strong is the scent
    scentColor = setScentColor(this);       // what color is the scent
 }

  boolean getScent()        { return scent; }
  float getScentStrength()  { return scentStrength; }
  int getScentColor()       { return scentColor; }

  int setScentColor( creature c ) {
    FloatList l;
    float s;
    int val;
    l = c.genome.list(scentTrait);
    s = l.get(5); // the 5th gene determines scent color for now
    // map function goes here
    if( s >= 0 ) {
      return 1;
    } else {
      return 2;
    }
  }

  // set scentStrength
  float setScentStrength( creature c ) {
    float s;
    s = c.genome.avg(scentTrait);
    // mapping function goes here
    return s;
  }

  // function setScent will calculate the creatures scent value
  boolean setScent( creature c ) {
    float s;
    s = c.genome.sum(scentTrait);
    // need to add a mapping function here
    if( s >= 0 ) {
      return true;
    } else {
      return false;
    }
  }

  // returns a vector to the creature's postion
  Vec2 getPos() {
    return(box2d.getBodyPixelCoord(body));
  }

  // adds some energy to the creature - called when the creature picks
  // up food/resource
  void addEnergy(int x) {
    float[] inputs = new float[metabolism.getNumInputs()];  // create the input array
    inputs[0] = 1;   // set the input values, starting with a bias
    inputs[1] = energy_reproduction/max_energy_reproduction;
    inputs[2] = energy_locomotion/max_energy_locomotion;
    inputs[3] = energy_health/max_energy_health;
    inputs[4] = round_counter*0.01;  // scale the round counter
    float[] outputs = new float[metabolism.getNumOutputs()];  // create the output array
    metabolism.calculate(inputs,outputs);  // run the network
  //  println(outputs[0] + " " + outputs[1] + " " + outputs[2]);  // debugging output
    float sum = 0;
    for(int i = 0; i < metabolism.getNumOutputs(); i++){
      outputs[i] = abs(outputs[i]);  // set negative outputs to positive - do something more clever later
      sum += outputs[i];  // sum the network outputs
    }
    energy_reproduction += x * outputs[0]/sum;
    energy_locomotion += x * outputs[1]/sum;
    energy_health += x * outputs[2]/sum;
//    println(x * outputs[0]/sum + " " + x * outputs[1]/sum + " " + x * outputs[2]/sum + " " + ((x * outputs[0]/sum )+ (x * outputs[1]/sum )+ (x * outputs[2]/sum)) );  // for debugging
    energy_reproduction = min(energy_reproduction, max_energy_reproduction);
    energy_locomotion = min(energy_locomotion, max_energy_locomotion);
    energy_health = min(energy_health, max_energy_health);
  }

  // Mapping from allele value to color is a sigmoid mapping to 0 to
  // 255 centered on 126
  private color getColor(int n) {
    // TODO: refactor for color per segment
    float[] inputs = new float[coloration.getNumInputs()];
    float redColor = genome.sum(redColorTrait);
    float greenColor = genome.sum(greenColorTrait);
    float blueColor = genome.sum(blueColorTrait);
    float alphaColor = genome.sum(alphaTrait);

    int r = 126 + (int)(126*(redColor/(1+abs(redColor))));
    int g = 126 + (int)(126*(greenColor/(1+abs(greenColor))));
    int b = 126 + (int)(126*(blueColor/(1+abs(blueColor))));
    int a = 126 + (int)(126*(alphaColor/(1+abs(alphaColor))));
    inputs[0] = 1;   // bias
    inputs[1] = timestep_counter*0.001;
    inputs[2] = health/maxHealth;
    inputs[3] = time_in_water/(timestep_counter+1); // percentage of time in water
    inputs[4] = r/255;
    inputs[5] = g/255;
    inputs[6] = b/255;
    inputs[7] = a/255;
    inputs[8] = n;
    float[] outputs = new float[coloration.getNumOutputs()];
    coloration.calculate(inputs, outputs);
    float sum = 0;
    for(int i = 0; i < coloration.getNumOutputs(); i++){
      outputs[i] = abs(outputs[i]);
      sum += outputs[i];
    }

    r = r*(1 + (int)outputs[0]);
    g = g*(1 + (int)outputs[1]);
    b = b*(1 + (int)outputs[2]);
    a = a*(1 + (int)outputs[3]);
    return color(r, g, b, a);
  }

  // Gets the end point of the ith segment/rib/spine used to create
  // the creatures body
  private Vec2 getPoint(int i) {
    Vec2 a = new Vec2();
    float segment = genome.sum(segments.get(i).endPoint);
    int lengthbase = 20;
    float l;
    if (segment < 0) {
      l = 1 + (lengthbase-1) * (1.0/(1+abs(segment)));
    }
    else {
      l = lengthbase + (2*lengthbase*(segment/(1+segment)));;
    }
    a.x = (float)(l * Math.sin((i)*PI/(numSegments)) );
    a.y = (float)(l * Math.cos((i)*PI/(numSegments)) );
    return a;
  }

  // Gets the end point of the ith segment/rib/spine on the other side
  // of the creatures body
  private Vec2 getFlippedPoint(int i) {
    // TODO: reduce code duplication
    Vec2 a = new Vec2();
    float segment = genome.sum(segments.get(i).endPoint);
    int lengthbase = 20;
    float l;
    if (segment < 0) {
      l = 1 + (lengthbase-1) * (1.0/(1+abs(segment)));
    }
    else {
      l = lengthbase + (2*lengthbase*(segment/(1+segment)));
    }
    a.x = (float)(-1 * l * Math.sin((i)*PI/(numSegments)) );
    a.y = (float)(l * Math.cos((i)*PI/(numSegments)) );
    return a;
  }

  // Calculate and return the width of the creature
  private float getWidth() {
    // TODO: Move this to creature
    float maxX = 0;
    Vec2 temp;
    for (int i = 0; i < numSegments; i++) {
      temp = getPoint(i);
      if (temp.x > maxX) {
        maxX = temp.x;
      }
    }
    return 2*maxX;
  }

  // Calculate and return the length of the creature
  private float getLength() {
    float maxY = 0;
    float minY = 0;
    Vec2 temp;
    for (int i = 0; i < numSegments; i++) {
      temp = getPoint(i);
      if (temp.y > maxY) {
        maxY = temp.y;
      }
      if (temp.y < minY) {
        minY = temp.y;
      }
    }
    return (maxY - minY);
  }

  float getMass() {
    return body.getMass();
  }

  // Forward force to accelerate the creature, evolved, but
  // (currently) doesn't change anytime durning a wave
  private float getForce() {
    // -infinity to infinity linear
    return (500 + 10 * genome.sum(forwardForce));
  }

  // How bouncy a creature is, one of the basic box2D body parameters,
  // no idea how it evolves or if it has any value to the creatures
  private float getRestitution() {
    // TODO: refactor for restitution per segment
    float r = genome.sum(restitutionTrait);
    return 0.5 + (0.5 * (r / (1 + abs(r))));
  }

  // can be from 2 to Genome.MAX_SEGMENTS
  int getNumSegments() {
    int ret = round(genome.avg(expressedSegments) + 8);
    if (ret < 2)
      return 2;
    if (ret > MAX_SEGMENTS)
      return MAX_SEGMENTS;
    return ret;
  }

  // Density of a creature for the box2D "physical" body.

  // Box2D automatically handles the mass as density times area, so
  // that when a force is applied to a body the correct acceleration
  // is generated.
  private float getDensity() {
    // TODO: refactor for density per segment

    // if the value is negative, density approaches zero asympototically from 10
    if (genome.sum(densityTrait) < 0)
      return 10 * (1 / (1 + abs(genome.sum(densityTrait))));
    // otherwise, the value is positive and density grows as 10 plus the square
    // root of the evolved value
    return 10 + sqrt(genome.sum(densityTrait)); // limit 0 to infinity
  }

  private void computeArmor() {
    armor = new FloatList(numSegments);
    for (int i = 0; i < numSegments; i++) {
      // compute armor value for each segment [0.1, infinity]
      float a = genome.avg(segments.get(i).armor);
      if (1 + a < 0.1)
        a = 0.1;
      else
        a = 1 + a;
      armor.append(a);
    }
  }

  // This function removes the body from the box2d world
  void killBody() {
      box2d.destroyBody(body);
  }

  double getCompat() {
    //return genome.getCompat();
    return 0;
  }

  
  // Calculates a creature's fitness, which determines its probability of reproducing
  void calcFitness() {
    fitness = 0;
    fitness += energy_locomotion;  // More energy = more fitness;  for now only locomotion energy is counted because that's what's used
    fitness += health;  // More health = more fitness
    if (alive) {        // Staying alive = more fitness
      fitness *= 2;
    }
    // Note that unrealistically dead creatures can reproduce, which is necessary in cases where a player kills a whole wave
  }

  void changeHealth(int h) {
    health += h;
    senses.Set_Current_Pain(-h);
  }

  float getFitness() {
    return fitness;
  }

  void calcBehavior(){
    for(int i = 0; i<brain.OUTPUTS; i++){
      for(int j = 0; j<brain.INPUTS; j++){
        current_actions[i] += (senses.brain_array[j]*brain.weights[i][j]);
      }
    }
  }

  // The update function is called every timestep
  // It updates the creature's postion, including applying turning torques,
  // and checks if the creature has died.
  void update() {
    Vec2 pos2 = box2d.getBodyPixelCoord(body);
    if (!alive) { // dead creatures don't update
      return;
    }
    timestep_counter++;
    float a = body.getAngle();
    float m = body.getMass();
    float f = 0;
    double torque = 0;

    senses.Update_Pain();
    senses.Update_Senses(pos2.x, pos2.y, a);
    
    calcBehavior();
    torque = current_actions[0];
    f = 1+current_actions[1];
    
    body.applyTorque((float)torque);
    // Angular velocity is reduced each timestep to mimic friction (and keep creatures from spinning endlessly)
    body.setAngularVelocity(body.getAngularVelocity() * 0.9);
    if (energy_locomotion > 0) { // If there's energy left apply force
      body.applyForce(new Vec2(f * cos(a - 4.7), f * sin(a - 4.7)), body.getWorldCenter());
      energy_locomotion = energy_locomotion - abs(2 + (f * 0.005));   // moving uses locomotion energy
    }

    // Creatures that run off one side of the world wrap to the other side.
    if (pos2.x < -0.5 * worldWidth) {
      pos2.x += worldWidth;
      body.setTransform(box2d.coordPixelsToWorld(pos2), a);
    }
    if (pos2.x > 0.5 * worldWidth) {
      pos2.x -= worldWidth;
      body.setTransform(box2d.coordPixelsToWorld(pos2), a);
    }
    if (pos2.y < -0.5 * worldHeight) {
      pos2.y += worldHeight;
      body.setTransform(box2d.coordPixelsToWorld(pos2), a);
    }
    if (pos2.y > 0.5 * worldHeight) {
      pos2.y -= worldHeight;
      body.setTransform(box2d.coordPixelsToWorld(pos2), a);
    }

    // if out of health have the creature "die". Stops participating
    // in the world, still exists for reproducton
    if (health <= 0) {
      alive = false;
      // if its no longer alive the body can be killed - otherwise it
      // still "in" the world.  Have to make sure the body isn't
      // referenced elsewhere
      killBody();
    }
    if (energy_health > 0 && health < maxHealth) {  // Spends energy devoted to health regen to increase the creature's health over time
      health = health + health_regen; // the creature health is increased
      energy_health = energy_health - regen_energy_cost; //the energy to regen is decreased
    }
  }

  // Called every timestep (if the display is on) draws the creature
  void display() {
    if (!alive) { // dead creatures aren't displayed
      return;
    }
    // We look at each body and get its screen position
    Vec2 pos = box2d.getBodyPixelCoord(body);
    // Get its angle of rotation
    float a = body.getAngle();

    Fixture f = body.getFixtureList();  // This is a list of the Box2D fixtures (segments) of the creature
    PolygonShape ps; // Create a polygone variable
    // set some shape drawing modes
    rectMode(CENTER);
    ellipseMode(CENTER);
    pushMatrix();  // Stores the current drawing reference frame
    translate(pos.x, pos.y);  // Move the drawing reference frame to the creature's position
    rotate(-a);  // Rotate the drawing reference frame to point in the direction of the creature
    stroke(0);   // Draw polygons with edges
    for(int c = 0; f != null; c++) {  // While there are still Box2D fixtures in the creature's body, draw them and get the next one
      c %= numSegments;
      fill(getColor(c)); // Get the creature's color
      strokeWeight(armor.get(c));
      ps = (PolygonShape)f.getShape();  // From the fixture list get the fixture's shape
      beginShape();   // Begin drawing the shape
      for (int i = 0; i < 3; i++) {
        Vec2 v = box2d.vectorWorldToPixels(ps.getVertex(i));  // Get the vertex of the Box2D polygon/fixture, translate it to pixel coordinates (from Box2D coordinates)
        vertex(v.x, v.y);  // Draw that vertex
      }
      endShape(CLOSE);
      f = f.getNext();  // Get the next fixture from the fixture list
    }
    strokeWeight(1);
    // Add some eyespots
    fill(0);
    Vec2 eye = getPoint(6);
    ellipse(eye.x, eye.y, 5, 5);
    ellipse(-1 * eye.x, eye.y, 5, 5);
    fill(255);
    ellipse(eye.x, eye.y - 1, 2, 2);
    ellipse(-1 * eye.x, eye.y - 1, 2, 2);
    popMatrix();

    senses.Draw_Sense(pos.x, pos.y, body.getAngle());
    /*
    // Draw the "feelers", this is mostly for debugging
    float sensorX,sensorY;
    // Note that the length (50) and angles PI*40 and PI*60 are the
    // same as when calculating the sensor postions in getTorque()
    int l = 50;
    sensorX = pos.x + l * cos(-1 * (body.getAngle() + PI * 0.40));
    sensorY = pos.y + l * sin(-1 * (body.getAngle() + PI * 0.40));
    sensorX = round((sensorX) / 20) * 20;
    sensorY = round((sensorY) / 20) * 20;
    line(pos.x, pos.y, sensorX, sensorY);
    //foodAhead = environ.checkForFood(sensorX,sensorY); // environ is a global
    sensorX = pos.x + l * cos(-1 * (body.getAngle() + PI * 0.60));
    sensorY = pos.y + l * sin(-1 * (body.getAngle() + PI * 0.60));
    sensorX = round((sensorX) / 20) * 20;
    sensorY = round((sensorY) / 20) * 20;
    line(pos.x, pos.y, sensorX, sensorY);
    */

    pushMatrix(); // Draws a "health" bar above the creature
    translate(pos.x, pos.y);
    noFill();
    stroke(0);
    // get the largest dimension of the creature
    int offset = (int)max(getWidth(), getLength());
    rect(0, -1 * offset, 0.1 * maxHealth, 3); // draw the health bar that much above it
    noStroke();
    fill(0, 0, 255);
    rect(0, -1 * offset, 0.1 * health, 3);
    //Text to display the round counter of each creature for debug purposes
    //text((int)round_counter, 0.2*width,-0.25*height);
    popMatrix();
  }

  class segIndex {  // This class is a helper. One of these is attached to every segment of every creature
    int segmentIndex;  // This class's only variable is an index corresponding to of the creature's segments this is, so its armor can be referenced later
  }

  // This function makes a Box2D body for the creature and adds it to the box2d world
  void makeBody(Vec2 center) {
    // Define the body and make it from the shape
    BodyDef bd = new BodyDef();  // Define a new Box2D body object
    bd.type = BodyType.DYNAMIC;  // Make the body dynamic (Box2d bodies can also be static: unmoving)
    bd.position.set(box2d.coordPixelsToWorld(center));  // set the postion of the body
    bd.linearDamping = 0.9;  // Give it some friction, could be evolved
    bd.setAngle(angle);      // Set the body angle to be the creature's angle
    body = box2d.createBody(bd);  // Create the body, note that it currently has no shape

    // Define a polygon object, this will be used to make the body fixtures
    PolygonShape sd;

    Vec2[] vertices3;  // Define an array of (3) vertices that will be used to define each fixture

    // For each segment
    for (int i = 0; i < numSegments; i++) {
      sd = new PolygonShape();  // Create a new polygon

      vertices3  = new Vec2[3];  // Create an array of 3 new vectors

      // Next create a segment, pie slice, of the creature by defining
      // 3 vertices of a poly gone

      // First vertex is at the center of the creature
      vertices3[0] = box2d.vectorPixelsToWorld(new Vec2(0, 0));
      // Second and third vertices are evolved, so get from the genome
      vertices3[1] = box2d.vectorPixelsToWorld(getPoint(i));
      vertices3[2] = box2d.vectorPixelsToWorld(getPoint(i + 1));

      // sd is the polygon shape, create it from the array of 3 vertices
      sd.set(vertices3, vertices3.length);
      // Create a new Box2d fixture
      FixtureDef fd = new FixtureDef();
      // Give the fixture a shape = polygon that was just created
      fd.shape = sd;
      fd.density = density;
      fd.restitution = getRestitution();
      fd.filter.categoryBits = 1; // creatures are in filter category 1
      fd.filter.maskBits = 65535;  // interacts with everything
//      fd.userData = new segIndex();
//      fd.userData.segmentIndex = i;
      body.createFixture(fd);  // Create the actual fixture, which adds it to the body
    }

    // now repeat the whole process for the other side of the creature
    for (int i = 0; i < numSegments; i++) {
      sd = new PolygonShape();
      vertices3  = new Vec2[3];
      //vertices[i] = box2d.vectorPixelsToWorld(getpoint(i));
      vertices3[0] = box2d.vectorPixelsToWorld(new Vec2(0,0));
      vertices3[1] = box2d.vectorPixelsToWorld(getFlippedPoint(i));
      vertices3[2] = box2d.vectorPixelsToWorld(getFlippedPoint(i + 1));
      sd.set(vertices3, vertices3.length);
      FixtureDef fd = new FixtureDef();
      fd.shape = sd;
      fd.density = density;
      fd.restitution = getRestitution();
      fd.filter.categoryBits = 1; // creatures are in filter category 1
      fd.filter.maskBits = 65535; // interacts with everything
//      fd.userData = new segIndex();
//      fd.userData.segmentIndex = i;
      body.createFixture(fd);
    }
  }
}
