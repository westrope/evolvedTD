import java.util.Comparator;

static int creature_count = 0;

class Gamete {
  int xPos, yPos;
  int time;
  int energy;
  Genome.Chromosome gamete;

  Gamete(int x, int y, int e, Genome.Chromosome g){
    xPos = x;
    yPos = y;
    time = timesteps;
    energy = e;
    gamete = g;
  }

  int getX()                      { return xPos; }
  int getY()                      { return yPos; }
  int getTime()                   { return time; }
  int getEnergy()                 { return energy; }
  Genome.Chromosome getGamete()   { return gamete; }
}

class GameteComparator implements Comparator<Gamete> {
  public int compare(Gamete x, Gamete y) {
    // return the Java comparison of two integers
    return Integer.valueOf(x.getTime()).compareTo(Integer.valueOf(y.getTime()));
  }
}

class creature {
  // stats
  int num;               // unique creature identifier
  boolean alive;         // dead creatures remain in the swarm to have a breeding chance
  float fitness;         // used for selection
  float health;          // 0 health, creature dies
  float maxHealth = 100; // TODO: should be evolved
  int health_regen = 1;  // value to set how much health is regenerated each timestep when energy is spent to regen
  int round_counter;     // counter to track how many rounds/generations the individual creature has been alive
  float baseMaxMovementSpeed = 800; //maximum speed without factoring in width and appendages
  float maxMovementSpeed;
  boolean selected;

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
  boolean scent;     // used to determine if creature is capable of producing scent
  int scentStrength; // how strong the creature's scent is
  int scentType;     // store an integer for different colors
  boolean CreatureScent = false;
  boolean ReproScent = false;
  boolean PainScent = false;

  // body
  Body body;
  float angle;
  int numSegments;
  color_network coloration;

  // Reproduction variables
  Vec2 sPos; // Starting position of creature
  int baseGameteCost = 10;    // Gametes base energy cost
  int baseGameteTime = 100;   // Gametes base create time in screen updates.
  int baseGameteEnergy = 500; // Gametes base extra energy
  int gameteTimeLapse = 0;    // Keeps track of time since last gamete

  ArrayList<Gamete> gameteStack = new ArrayList<Gamete>(); // Holds the gametes and their map positions.

  ArrayList<Segment> segments = new ArrayList<Segment>(numSegments);
  ArrayList<Appendage> appendages = new ArrayList<Appendage>(numSegments);
  
  // Data Collection variables
  float total_energy_space;
  float total_energy_consumed = 0;
  float locomotion_used = 0;
  float reproduction_used = 0;
  float reproduction_passed = 0;
  float health_used = 0;
  int   hits_by_tower = 0;
  int   hp_removed_by_tower = 0;
  

  class Segment {
    int index;
    float armor;
    float density;
    float restitution;
    Vec2 frontPoint;
    Vec2 backPoint;

    Segment(int i) {
      index = i;
      armor = getArmor();
      density = getDensity();
      density *= armor;
      restitution = getRestitution();
      frontPoint = getFrontPoint();
      backPoint = getBackPoint();
    }

    private float getArmor() {
      float a = (genome.avg(segmentTraits.get(index).armor));
      if ((1+a) < 0.1) return 0.1;
      return (a+1);
    }

    private float getDensity() {
      float d = (genome.sum(segmentTraits.get(index).density));
      // if the value is negative, density approaches zero asympototically from 10
      if (d < 0)
        return 10 * (1 / (1 + abs(d)));
      // otherwise, the value is positive and density grows as 10 plus the square
      // root of the evolved value
      return 10 + sqrt(d); // limit 0 to infinity
    }

    private float getRestitution() {
      float r = (genome.sum(segmentTraits.get(index).restitution));
      return 0.5 + (0.5 * (r / (1 + abs(r))));
    }

    private Vec2 getFrontPoint() {
      Vec2 p = new Vec2();
      float endpoint;
      if (index == (numSegments-1)) endpoint = genome.sum(segmentTraits.get(index).appendageSize); // frontmost point is undefined and therefore we use the unused appendageSize trait
      else endpoint = genome.sum(segmentTraits.get(index+1).endPoint);
      int lengthbase = 20;
      float l;
      if (endpoint < 0) {
        l = 1 + (lengthbase-1) * (1.0/(1+abs(endpoint)));
      }
      else {
        l = lengthbase + (2*lengthbase*(endpoint/(1+endpoint)));;
      }
      p.x = (float)(l * Math.sin((index+1)*PI/(numSegments)) );
      p.y = (float)(l * Math.cos((index+1)*PI/(numSegments)) );
      return p;
    }

    private Vec2 getBackPoint() {
      Vec2 p = new Vec2();
      float endpoint = genome.sum(segmentTraits.get(index).endPoint);
      int lengthbase = 20;
      float l;
      if (endpoint < 0) {
        l = 1 + (lengthbase-1) * (1.0/(1+abs(endpoint)));
      }
      else {
        l = lengthbase + (2*lengthbase*(endpoint/(1+endpoint)));;
      }
      p.x = (float)(l * Math.sin((index)*PI/(numSegments)) );
      p.y = (float)(l * Math.cos((index)*PI/(numSegments)) );
      return p;
    }
  }

  //////////////////////////////////////////////////////////////////////////////

  class Appendage {
    int index;
    float size;
    float armor;
    float density;
    float restitution;
    float waterForce;
    float grassForce;
    float mountainForce;
    float waterForcePercent;
    float grassForcePercent;
    float mountainForcePercent;
    float angle;
    float spread;
    Vec2 originPoint;
    Vec2 frontPoint;
    Vec2 backPoint;

    Appendage(int i) {
      index = i;
      size = getSize();
      if (size>0) {
        armor = getArmor();
        density = getDensity();
        density *= armor;
        getForces();
        angle = getAngle();
        spread = getSpread();
        originPoint = getOriginPoint();
        frontPoint = getFrontPoint();
        backPoint = getBackPoint();
      }
    }

    private float getSize() {
      float ret = genome.sum(segmentTraits.get(index).appendageSize);
      if (ret < 0) ret *= -1;
      if (ret < 0.3) ret = 0;
      return ret;
    }

    private float getArmor() {;
      float a = (genome.avg(appendageTraits.get(index).armor));
      if ((1+a) < 0.1) return 0.1;
      return (a+1);
    }

    private float getDensity() {
      float d = (genome.sum(appendageTraits.get(index).density));
      // if the value is negative, density approaches zero asympototically from 10
      if (d < 0)
        return 10 * (1 / (1 + abs(d)));
      // otherwise, the value is positive and density grows as 10 plus the square
      // root of the evolved value
      return 10 + sqrt(d); // limit 0 to infinity
    }

    private float getRestitution() {
      float r = (genome.sum(appendageTraits.get(index).restitution));
      return 0.5 + (0.5 * (r / (1 + abs(r))));
    }

    void getForces() { //mapping function is inverse quadratic and then values are made proportional to their sum
      float water = (genome.avg(appendageTraits.get(index).waterForce));
      waterForce = ((-1/(1.01+(water*water)))+1);
      //waterForce *= 6;
      float grass = (genome.avg(appendageTraits.get(index).grassForce));
      grassForce = ((-1/(1.01+(grass*grass)))+1);
      //grassForce *= 4;
      float mountain = (genome.avg(appendageTraits.get(index).mountainForce));
      mountainForce = ((-1/(1.01+(mountain*mountain)))+1);
      //mountainForce *= 4;
      float divisor = waterForce+grassForce+mountainForce;
      waterForcePercent = waterForce/divisor;
      grassForcePercent = grassForce/divisor;
      mountainForcePercent = mountainForce/divisor;
    }

    private float getAngle() {
      return (((index+1)*(PI/numSegments))-(PI/2));//(float)(Math.atan((segments.get(index).backPoint.x-segments.get(index).frontPoint.x)/(segments.get(index).backPoint.y-segments.get(index).frontPoint.y)));
    }

    private float getSpread() {
      return (PI/6);//(float)((Math.acos(((mountainForce*mountainForce)+(grassForce*grassForce)-(waterForce*waterForce))/(2*mountainForce*grassForce)))/2);
    }

    private Vec2 getOriginPoint() { // point of origin of the appendages is the front point of the associated segment
      return new Vec2(segments.get(index).frontPoint.x, segments.get(index).frontPoint.y);
    }

    private Vec2 getFrontPoint() {
      return new Vec2(((float)(/*grassForce*/1*(Math.sin(spread+angle+(PI/2))))*10*size)+originPoint.x, ((float)(/*grassForce*/1*(Math.cos(spread+angle+(PI/2))))*10*size)+originPoint.y);
    }

    private Vec2 getBackPoint() {
      return new Vec2(((float)(/*mountainForce*/1*(Math.sin((-1*spread)+angle+(PI/2))))*10*size)+originPoint.x, ((float)(/*mountainForce*/1*(Math.cos((-1*spread)+angle+(PI/2))))*10*size)+originPoint.y);
    }
  }

  // Constructor, creates a new creature at the given location and angle

  // This constructor is generally only used for the first wave, after
  // that creatures are created from parents.
  creature(float x, float y, float a) {
    angle = a;
    genome = new Genome();
    construct((float)20000, new Vec2(x, y));
  }

  // construct a new creature with the given genome and energy
  creature(Genome g, float e) {
    angle = random(0, 2 * PI); // start at a random angle
    genome = g;
    // Currently creatures are 'born' around a circle a fixed distance
    // from the tower. Birth locations should probably be evolved as
    // part of the reproductive strategy and/or behavior
    Vec2 pos = new Vec2(0.45 * worldWidth * sin(angle),
                        0.45 * worldWidth * cos(angle));
    construct(e, pos);
  }

  // construct a new creature with the given genome, energy and position
  creature(Genome g, float e, Vec2 pos) {
    angle = random(0, 2 * PI); // start at a random angle
    genome = g;
    construct(e, pos);
  }

  void construct(float e, Vec2 pos) { // this function contains all the overlap of the constructors
    num = creature_count++;
    senses = new Sensory_Systems(genome);
    brain = new Brain(genome);
    current_actions = new float[brain.OUTPUTS];
    
    // used for data collection
    sPos = pos.clone();
    total_energy_space = max_energy_locomotion + max_energy_reproduction + max_energy_health;
    

    numSegments = getNumSegments();
    for (int i = 0; i < numSegments; i++) segments.add(new Segment(i));
    for (int i = 0; i < (numSegments-1); i++) appendages.add(new Appendage(i));

    makeBody(pos);   // call the function that makes a Box2D body
    body.setUserData(this);     // required by Box2D

    float energy_scale = 500; // scales the max energy pool size
    float max_sum = abs(genome.sum(maxReproductiveEnergy)) + abs(genome.sum(maxLocomotionEnergy)) + abs(genome.sum(maxHealthEnergy));
    max_energy_reproduction = body.getMass() * energy_scale * abs(genome.sum(maxReproductiveEnergy))/max_sum;
    max_energy_locomotion = body.getMass() * energy_scale * abs(genome.sum(maxLocomotionEnergy))/max_sum;
    max_energy_health =  body.getMass() * energy_scale * abs(genome.sum(maxHealthEnergy))/max_sum;
    energy_reproduction = 0;                                // have to collect energy to reproduce
    energy_locomotion = min(e,max_energy_locomotion);       // start with energy for locomotion, the starting amount should come from the gamete and should be evolved
    energy_health = 0;                                      // have to collect energy to regenerate, later this may be evolved
    //println(max_energy_reproduction + " " + max_energy_locomotion + ":" +energy_locomotion + " "+ max_energy_health);  // for debugging
    metabolism = new metabolic_network(genome);
    coloration = new color_network(genome);
    health = maxHealth;         // initial health (probably should be evolved)
    fitness = 0;                // initial fitness
    alive = true;               // creatures begin life alive
    selected = false;

    maxMovementSpeed = baseMaxMovementSpeed - (2*getWidth());
    for (Appendage app : appendages) maxMovementSpeed += 50*app.size; // Every appendage contributes to overall movement speed a little, 15 to start out. This encourages the evolution of appendages in the first place.

    scent = setScent();                 // does creature produce scent
    scentStrength = setScentStrength(); // how strong is the scent
    scentType = setScentType();         // what color is the scent
  }

  boolean getScent()     { return scent; }
  int getScentStrength() { return scentStrength; }
  int getScentType()     { return scentType; }

  int setScentType() {
    if (scent) {
      return 1;
    }
    return 0;
  }

  void TurnOnReproScent() {
    if (!scent) {
      return;
    }
    if (genome.sumX(scentTrait) >= 0) {
      ReproScent = true;
      CreatureScent = false;
      PainScent = false;
    }
  }

  void TurnOffReproScent() {
    ReproScent = false;
    if (scent) {
      CreatureScent = true;
    }
  }

  void TurnOnPainScent() {
    if (!scent) {
      return;
    }
    if (genome.sumY(scentTrait) >= 0) {
      ReproScent = false;
      CreatureScent = false;
      PainScent = true;
    }
  }

  void TurnOffPainScent() {
    PainScent = false;
    if (scent) {
      CreatureScent = true;
    }
  }

  // set scentStrength
  int setScentStrength() {
    int s;
    float tmp;
    tmp = genome.avg(scentTrait);
    if (tmp < -1 )
      s = 0;
    else if (tmp >= -1 && tmp < 0 )
      s = 1;
    else if (tmp >= 0 && tmp < 1 )
      s = 2;
    else
      s = 3;
    // mapping function goes here
    return s;
  }

  // function setScent will calculate the creatures scent value
  boolean setScent() {
    float s;
    s = genome.sum(scentTrait);
    // need to add a mapping function here
    if (s >= 0) {
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
    
    // data collection
    total_energy_consumed += x;
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

  // Calculate and return the width of the creature
  private float getWidth() {
    // TODO: Move this to creature
    float minX = 0;
    float temp;
    for (int i = 0; i < numSegments-1; i++) {
      temp = segments.get(i).frontPoint.x;
      if (temp < minX) minX = temp;
    }
    return (-2*minX);
  }

  // Calculate and return the length of the creature
  private float getLength() {
    float maxY = 0;
    float minY = 0;
    float temp = segments.get(0).backPoint.y;
    if (temp > maxY) maxY = temp;
    if (temp < minY) minY = temp;
    for (int i = 0; i < numSegments; i++) {
      temp = segments.get(i).frontPoint.y;
      if (temp > maxY) maxY = temp;
      if (temp < minY) minY = temp;
    }
    return (maxY - minY);
  }

  float getMass() {
    return body.getMass();
  }
  
  float getArmor() {  // gets the sum of armor on all segments and appendages
    float value = 0;
    for (Segment s : segments) {
      value += s.armor;
    }
    for (Appendage a : appendages) {
      value += a.armor;
    }
    
    return value;
  }
  
  float getDensity() { // gets the sum of density on all segments and appendages
    float value = 0;
    for (Segment s : segments) {
      value += s.density;
    }
    for (Appendage a : appendages) {
      value += a.density; 
    }
    
    return value;
  }

  // can be from 2 to Genome.MAX_SEGMENTS
  int getNumSegments() {
    int ret = round(genome.sum(expressedSegments) + STARTING_NUMSEGMENTS);
    if (ret < 2)
      return 2;
    if (ret > MAX_SEGMENTS)
      return MAX_SEGMENTS;
    return ret;
  }

  // This function removes the body from the box2d world
  void killBody() {
    box2d.destroyBody(body);
  }

  double getCompat() {
    //return genome.getCompat();
    return 0;
  }

  // This is the base turning force, it is modified by getBehavior()
  // above, depending on what type of object was sensed to start
  // turning
  private int getTurningForce() {
    // -infinity to infinity linear
    return (int)(100 + 10 * genome.sum(turningForce));
  }

  // Returns the amount of turning force (just a decimal number) the
  // creature has evolved to apply when it senses either food, another
  // creature, a rock, or a (food) scent.
  private double getBehavior(Trait trait) {
    return getTurningForce() * genome.sum(trait); // there's a turning force
  }

  void changeHealth(int h) {
    health += h;
    senses.Set_Current_Pain(-h);
    
    // data collection
    hits_by_tower++;
    hp_removed_by_tower += h;
  }

  void calcBehavior(){
    for(int i = 0; i<brain.OUTPUTS; i++){
      current_actions[i] = 0;
      for(int j = 0; j<brain.INPUTS; j++){
        current_actions[i] += (senses.brain_array[j]*brain.weights[i][j]);
      }
    }
  }

  // The update function is called every timestep
  // It updates the creature's postion, including applying turning torques,
  // and checks if the creature has died.
  void update() {
    if (!alive) { // dead creatures don't update
      return;
    }
    Vec2 pos2 = box2d.getBodyPixelCoord(body);
    timestep_counter++;
    float a = body.getAngle();
    float m = body.getMass();
    float f = 0;
    double torque = 0;

    senses.Update_Pain();
    senses.Update_Senses(pos2.x, pos2.y, a);

    calcBehavior();
    torque = current_actions[0]*0.01;

    // force is a percentage of max movement speed from 10% to 100%, averaging 80%
    // depending on the output of the neural network in current_actions[1], the movement force may be backwards
    // as of now the creatures never completely stop moving
    f = Utilities.MovementForceSigmoid(current_actions[1]);
    if (current_actions[1] < -50) f *= -1;
    //f = 0.8;
    f *= maxMovementSpeed;

    int switchnum;
    if (environ.checkForLiquid((double)pos2.x, (double)pos2.y) == 1) {
      time_in_water++;
      switchnum = 0;
    }
    else if (environ.checkForMountain((double)pos2.x, (double)pos2.y) == 1) switchnum = 1;
    else switchnum = 2;
    //println("Creature (" + pos2.x + ", " + pos2.y + ")");
    //println("Base move speed: " + f);
    float base = f;

    // appendages will change the force depending on the environment
    for (Appendage app : appendages) {
      if (app.size > 0) { // if the appendage exists
        switch (switchnum) {
        case 0: // if the creature's center is in water
          f -= (base*app.grassForcePercent)/numSegments;
          f += (2*base*app.waterForcePercent)/numSegments;
          f -= (base*app.mountainForcePercent)/numSegments;
          break;
        case 1: // if the creature's center is on a mountain
          f -= (base*app.grassForcePercent)/numSegments;
          f -= (base*app.waterForcePercent)/numSegments;
          f += (2*base*app.mountainForcePercent)/numSegments;
          break;
        case 2: // if the creature's center is on grass
          f += (2*base*app.grassForcePercent)/numSegments;
          f -= (base*app.waterForcePercent)/numSegments;
          f -= (base*app.mountainForcePercent)/numSegments;
          break;
        }
      }
    }

    //println("Environmental speed: " + f);

    body.applyTorque((float)torque);
    // Angular velocity is reduced each timestep to mimic friction (and keep creatures from spinning endlessly)
    body.setAngularVelocity(body.getAngularVelocity() * 0.9);

    if (energy_locomotion > 0) { // If there's energy left apply force
      body.applyForce(new Vec2(f * cos(a - (PI*1.5)), f * sin(a - (PI*1.5))), body.getWorldCenter());
      energy_locomotion = energy_locomotion - abs(2 + (f * 0.005));   // moving uses locomotion energy
      energy_locomotion = (energy_locomotion - abs((float)(torque * 0.05)));
      
      // data collection
      locomotion_used += (abs(2 + (f * 0.005)) + abs((float)(torque * 0.05)));
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

    // If a creature runs our of locomotion energy it starts to lose health
    // It might make more sense to just be based on health energy, but creatures start with zero health energy and health energy doesn't always decrease
    if(energy_locomotion <= 0){
      health = health -1;
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


    // Gamete production
    // if creature has enough energy and enough time has passed,
    // lay a gamete at current position on the map.
    if (gameteTimeLapse > baseGameteTime + genome.avg(gameteTime)
        && energy_reproduction > (baseGameteCost + genome.avg(gameteCost)
                                  + baseGameteEnergy + genome.avg(gameteEnergy))) {

      // Get the tile position of the creature
      int xPos = (int) (box2d.getBodyPixelCoord(body).x / cellWidth);
      int yPos = (int) (box2d.getBodyPixelCoord(body).y / cellHeight);
      int energy = (int) (baseGameteEnergy * (1+genome.avg(gameteEnergy)));

      // Create gamete and place in gameteSack
      Gamete g = new Gamete(xPos, yPos, energy,
                            (Genome.Chromosome)genome.getGametes().get(0));
      gameteStack.add(g);

      // remove energy from creature
      energy_reproduction -= (baseGameteCost * (1+genome.avg(gameteCost)) + baseGameteEnergy * (1+genome.avg(gameteEnergy)));
      reproduction_used += (baseGameteCost * (1+genome.avg(gameteCost)));
      reproduction_passed += (baseGameteEnergy * (1+genome.avg(gameteEnergy)));

      gameteTimeLapse = 0;
    }
    else gameteTimeLapse++;


    // Spends energy devoted to health regen to increase the
    // creature's health over time
    if (energy_health > 0 && health < maxHealth) {
      health = health + health_regen;
      energy_health = energy_health - regen_energy_cost;
      
      // data collection
      health_used += regen_energy_cost;
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

    PolygonShape ps; // Create a polygone variable
    // set some shape drawing modes
    rectMode(CENTER);
    ellipseMode(CENTER);
    pushMatrix();  // Stores the current drawing reference frame
    translate(pos.x, pos.y);  // Move the drawing reference frame to the creature's position
    rotate(-a);  // Rotate the drawing reference frame to point in the direction of the creature

    if (selected) // purple
      stroke(76, 0, 153);
    else          // black
      stroke(0);

    for(Fixture f = body.getFixtureList(); f != null; f = f.getNext()) {  // While there are still Box2D fixtures in the creature's body, draw them and get the next one
      if (f.getUserData().getClass() == Segment.class) {
        fill(getColor(((Segment)f.getUserData()).index)); // Get the creature's color
        if ((((Segment)f.getUserData()).armor) > 1)
          strokeWeight((((((Segment)f.getUserData()).armor)-1)*50)+1); // make armor more visible
        else
          strokeWeight(((Segment)f.getUserData()).armor);
      }
      if (f.getUserData().getClass() == Appendage.class) {
        fill(getColor(((Appendage)f.getUserData()).index)); // Get the creature's color
        if ((((Appendage)f.getUserData()).armor) > 1)
          strokeWeight((((((Appendage)f.getUserData()).armor)-1)*50)+1); // make armor more visible
        else
          strokeWeight(((Appendage)f.getUserData()).armor);
      }
      ps = (PolygonShape)f.getShape();  // From the fixture list get the fixture's shape
      beginShape();   // Begin drawing the shape
      for (int i = 0; i < 3; i++) {
        Vec2 v = box2d.vectorWorldToPixels(ps.getVertex(i));  // Get the vertex of the Box2D polygon/fixture, translate it to pixel coordinates (from Box2D coordinates)
        vertex(v.x, v.y);  // Draw that vertex
      }
      endShape(CLOSE);
    }
    strokeWeight(1);
    // Add some eyespots
    fill(0);
    Vec2 eye = segments.get(round(numSegments*0.74)).frontPoint;;
    ellipse(eye.x, eye.y, 5, 5);
    ellipse(-1 * eye.x, eye.y, 5, 5);
    fill(255);
    ellipse(eye.x, eye.y - 1, 2, 2);
    ellipse(-1 * eye.x, eye.y - 1, 2, 2);
    popMatrix();

    senses.Draw_Sense(pos.x, pos.y, body.getAngle());

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
      Vec2 front = segments.get(i).frontPoint;
      Vec2 back = segments.get(i).backPoint;
      vertices3[1] = box2d.vectorPixelsToWorld(front);
      vertices3[2] = box2d.vectorPixelsToWorld(back);

      // sd is the polygon shape, create it from the array of 3 vertices
      sd.set(vertices3, vertices3.length);
      // Create a new Box2d fixture
      FixtureDef fd = new FixtureDef();
      // Give the fixture a shape = polygon that was just created
      fd.shape = sd;
      fd.density = segments.get(i).density;
      fd.restitution = segments.get(i).restitution;
      fd.filter.categoryBits = 1; // creatures are in filter category 1
      fd.filter.maskBits = 65535;  // interacts with everything
      fd.userData = segments.get(i);
      body.createFixture(fd);  // Create the actual fixture, which adds it to the body

      // now tweak and repeat for the symmetrically opposite fixture
      front.x *= -1;
      back.x *= -1;
      vertices3[1] = box2d.vectorPixelsToWorld(front);
      vertices3[2] = box2d.vectorPixelsToWorld(back);
      sd.set(vertices3, vertices3.length);
      fd.shape = sd;
      body.createFixture(fd);  // Create the actual fixture, which adds it to the body

      if (i == (numSegments-1))break;
      if (appendages.get(i).size > 0) {
        Vec2 orig = appendages.get(i).originPoint;
        vertices3[0] = box2d.vectorPixelsToWorld(orig);
        front = appendages.get(i).frontPoint;
        back = appendages.get(i).backPoint;
        vertices3[1] = box2d.vectorPixelsToWorld(front);
        vertices3[2] = box2d.vectorPixelsToWorld(back);
        sd.set(vertices3, vertices3.length);
        fd.shape = sd;
        fd.density = appendages.get(i).density;
        fd.restitution = appendages.get(i).restitution;
        fd.userData = appendages.get(i);
        body.createFixture(fd);  // Create the actual fixture, which adds it to the body

        // now tweak and repeat for the symmetrically opposite fixture
        orig.x *= -1;
        vertices3[0] = box2d.vectorPixelsToWorld(orig);
        front.x *= -1;
        back.x *= -1;
        vertices3[1] = box2d.vectorPixelsToWorld(front);
        vertices3[2] = box2d.vectorPixelsToWorld(back);
        sd.set(vertices3, vertices3.length);
        fd.shape = sd;
        body.createFixture(fd);  // Create the actual fixture, which adds it to the body
      }
    }
  }
}
