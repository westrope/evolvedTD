// Copyright (C) 2015 evolveTD Copyright Holders

/* This class holds a population of creatures in an arraylist called swarm.
 * Each generation/wave the whole population attacks.
 */
import java.util.Collections;

class population {
  ArrayList<creature> swarm;
  static final int POP_SIZE = 50;

  float baseGameteChance = 0.4; // Base gamete success rate
  int baseGameteRadius = 6; // Base gamete mating range

  population() {
    swarm = new ArrayList<creature>();
    float a;
    for (int i = 0; i < POP_SIZE; i++) {
      a = i*(2*PI/POP_SIZE); // distribute creatures around a circle, next line adds a little noise to their positions.
      creature c = new creature(0.45*(1+random(-0.05,0.05))*worldWidth*sin(a),0.45*(1+random(-0.05,0.05))*worldWidth*cos(a),a);
      swarm.add(c);
    }
  }

  void update() {
    for (creature c : swarm) {
      c.update();
    }
  }

  void display() {
    for (creature c : swarm) {
      c.display();
    }
  }

  Vec2 vec_to_random_creature() {
    Vec2 v = new Vec2(0,0);
    creature c;
    if (get_alive() == 0) {
      return v; // none left alive
    }
    c = swarm.get(int(random(swarm.size())));
    while(!c.alive) {
      c = swarm.get(int(random(swarm.size())));
    }
    return c.getPos();
  }

  Vec2 closest(Vec2 v) {
    Vec2 ret = new Vec2(0,0);
    float temp, minDistance = 0;
    boolean first = true;
    for (creature c: swarm) {
      if (c.alive) { // skip non-alive creatures
        if (first) {
          ret = c.getPos();
          minDistance = sqrt((ret.x-v.x)*(ret.x-v.x)+(ret.y-v.y)*(ret.y-v.y));
          first = false;
        }
        else {
          temp = sqrt((c.getPos().x-v.x)*(c.getPos().x-v.x)+(c.getPos().y-v.y)*(c.getPos().y-v.y));
          if (temp < minDistance ) {
             minDistance = temp;
             ret = c.getPos();
          }  
        }
      }
    }
    return ret;
  }
  
  Vec2 highestAlpha() {
    Vec2 ret = new Vec2(0,0);
    float temp, minAlpha = 0;
    boolean first = true;
    for (creature c: swarm) {
      if (c.alive) {
        if (first) {
          minAlpha = c.genome.sum(alphaTrait);
          ret = c.getPos();
          first = false;
        }
        else {
          temp = c.genome.sum(alphaTrait);
          if (temp < minAlpha ) {
             minAlpha = temp;
             ret = c.getPos();
          }  
        }
      }
    }
    return ret;
  }
  
    Vec2 highestWidth() {
    Vec2 ret = new Vec2(0,0);
    float temp, maxWidth = 0;
    boolean first = true;
    for (creature c: swarm) {
      if (c.alive) {
        if (first) {
          maxWidth = c.getWidth();
          ret = c.getPos();
          first = false;
        }
        else {
          temp = c.getWidth();
          if (temp > maxWidth) {
            maxWidth = temp;
            ret = c.getPos();
          }
        }
      }
    }
    return ret;
  }
  
    Vec2 lowestWidth() {
    Vec2 ret = new Vec2(0,0);
    float temp, minWidth = 0;
    boolean first = true;
    for (creature c: swarm) {
      if (c.alive) {
        if (first) {
          minWidth = c.getWidth();
          ret = c.getPos();
          first = false;
        }
        else {
          temp = c.getWidth();
          if (temp < minWidth) {
            minWidth = temp;
            ret = c.getPos();
          }
        }
      }
    }
    return ret;
  }

  // returns the number of living creatures, used to decide whether to
  // end a wave
  int get_alive() {
    int counter = 0;
    for (creature c: swarm) {
      if (c.alive) {
        counter++;
      }
    }
    return counter;
  }

  void set_creatures() {
    Vec2 p = new Vec2();
    for (creature c: swarm) {
      if (c.alive) { // only place living creatures
        p = c.getPos();
        // tell the global environment where the creatures are
        environ.place_creature(c, p.x, p.y);
      }
    }
  }

  /* Computes compatibility of two gametes
   *
   * Looks at the compatibility loci of the parents passed in, and
   * determines whether they are reproductively compatible.  Viability
   * is based on the difference between the loci, with the probability
   * being the normal distribution value at the point where the
   * difference is.  Visually, the probability that an offspring is
   * viable is the Y-value of the point on a normal distribution where
   * x = difference between compat genes.  If the difference is more
   * than 2 standard deviations, then the parents are by default
   * incompatible
   */
  boolean areGametesCompatible(Chromosome gamete1, Chromosome gamete2) {
    if (gamete1 == null || gamete2 == null)
      return false;

    // standard deviation: 5.0 ---- This determines the "speciation
    // rate" by restricting the range of compatible values in the
    // genome
    double sDev = 5.0;

    // mean at the Y axis --------- Changing this // will move the
    // "most compatibility" value // left or right of zero
    double mean = 0.0;

    // This is the location to evaluate the probability.  The further
    // away from the center of the curve, the less likely to be
    // compatible.
    double x_val = Utilities.Sigmoid(gamete1.sum(compatibility), 50, 50)
      - Utilities.Sigmoid(gamete2.sum(compatibility), 50, 50);

    double r = Math.random();

    // returns whether r is at or below the curve at the x_val point
    return r <= (1.0 / (sDev * sqrt((float)(2 * Math.PI)))
                 * Math.exp(-1 * ((x_val - mean)*(x_val - mean)
                                  / (2 * sDev * sDev))));
  }

  // scales fitness to O(10)
  int nGametes(float fitness) {
    return int(fitness/1000);
  }

  // creates the next generation
  void next_generation() {
    ArrayList<Gamete> gametes = new ArrayList();
    ArrayList<creature> generation = new ArrayList<creature>();
    
    for (creature c : swarm) {
      // Kill the bodies of any creatures that are still alive
      if (c.alive) {
        c.killBody();
      }
      gametes.addAll(c.gameteStack);
    }
    // at end of wave, update data collection
    updateData();

    // "kill" all creatures so camera stops following them
    for (creature c : swarm) {
      c.alive = false;
    }

    int multiplier = 0;
    int range;
    int variance = 15; // Used for variable pop size with random selection

    while (generation.size() < POP_SIZE) {
      // increase search range with each pass thru.
      range = multiplier++ * 5;
      //TODO: decrease success chance when range is increased.

      // print error if not enough gametes
      if (gametes.size() < 2) {
        println("ERROR: Not enough gametes");
        break;
      }

      ArrayList<Gamete> inProximity = new ArrayList<Gamete>();
      Gamete g1;
      // i is first gamete j is its chosen mate
      for (int i=0; i < variance && i < gametes.size(); i++) {
        int rand = int(random(gametes.size()));
        g1 = gametes.get(rand);

        // get gametes in proximity
        for (Gamete g2 : gametes) {
          if (g2 == g1)
            continue;

          // Check if g2 is in range of g1
          if (g2.xPos > g1.xPos - range && g2.xPos < g1.xPos + range && // within x range
              g2.yPos > g1.yPos - range && g2.yPos < g1.yPos + range) { // within y range
            inProximity.add(g2);
          }
        }

        // if any match has been found:
        if (!inProximity.isEmpty()) {
          Gamete g2 = inProximity.get(int(random(inProximity.size())));
          gametes.remove(g1); //remove first gamete
          gametes.remove(g2); //remove second gamete

          // Gamete coordinates
          int px = (g1.xPos - (g1.xPos-g2.xPos)/2);
          int py = (g1.yPos - (g1.yPos-g2.yPos)/2);
          Vec2 pos = new Vec2(px, py);

          // Check coordinates for other creatures or rocks spawned in this tile.
          while( checkForCreature(pos, generation) || checkForRock(pos, rocks)){};

          pos.x *= cellWidth;
          pos.y *= cellHeight;
          creature c = new creature(new Genome(g1.getGamete(), g2.getGamete()),
                                      10000 + g1.energy + g2.energy, pos);
          c.parents[0] = g1.parent.num;
          c.parents[1] = g2.parent.num;
          
          c.grandparents[0] = g1.parent.parents[0];
          c.grandparents[1] = g1.parent.parents[1];
          c.grandparents[2] = g2.parent.parents[0];
          c.grandparents[3] = g2.parent.parents[1]; 
          
          generation.add(c);
        }
      }
      swarm = generation;
    }
  }
  
  Boolean checkForCreature(Vec2 pos, ArrayList<creature> list) {
    Boolean check = false;
    
    // Check all creatures in list
    for (int c=0; c < list.size(); c++) {
      Vec2 posCheck = box2d.getBodyPixelCoord(list.get(c).body);
      
      if (checkSpawnLocation(pos, posCheck)) {
        c = -1; // must make it thru whole list without needing to move.
        check = true;
      }
    }
    return check;
  }
  
  Boolean checkForRock(Vec2 pos, ArrayList<rock> list) {
    Boolean check = false;
    
    // Check all rocks in list
    for (int c=0; c < list.size(); c++) {
      Vec2 posCheck = box2d.getBodyPixelCoord(list.get(c).the_rock);
      
      if (checkSpawnLocation(pos, posCheck)) {
        c = -1; // must make it thru whole list without needing to move.
        check = true;
      }
    }
    return check;
  }
  
  Boolean checkSpawnLocation(Vec2 pos, Vec2 posCheck) {
    Boolean check = false;
    
    // Check coordinates for other collidables spawned in this tile.
    int xCheck = (int)(posCheck.x / cellWidth);
    int yCheck = (int)(posCheck.y / cellHeight);
    
    // while collidable already occupies tile 
    // (3 is the safety range to prevent stacking)
    while ((pos.x <= xCheck + 3) && (pos.x >= xCheck - 3) && 
           (pos.y <= yCheck + 3) && (pos.y >= yCheck - 3)) {
      check = true;
      
      // Move new creature in a random direction
      switch ((int)random(8)) {
        case 0: //North
          pos.y--;
          break;
        case 1: //NorthEast
          pos.y--;
          pos.x++;
          break;
        case 2: //East
          pos.x++;
          break;
        case 3: //SouthEast
          pos.y++;
          pos.x++;
          break;
        case 4: //South
          pos.y++;
          break;
        case 5: //SouthWest
          pos.y++;
          pos.x--;
          break;
        case 6: //West
          pos.x--;
          break;
        case 7: //NorthWest
          pos.y--;
          pos.x++;
          break;
        default: break;
      }
      
      // Make sure position is still in bounds
      if (pos.x >= worldWidth   / cellWidth)  pos.x = worldWidth / cellWidth - 5;
      if (pos.x <= 0)                         pos.x = 5;
      if (pos.y >= worldHeight  / cellHeight) pos.y = worldHeight / cellHeight - 5;
      if (pos.y <= 0)                         pos.y = 5;
    }

    return check;
  }
  
  void updateData() {
    
    //average variables
    float massAvg = 0, widthAvg = 0, denseAvg = 0, armorAvg = 0, 
          wingAvg = 0, wingSizeAvg = 0, antennaeAvg = 0, colorAvg = 0, 
          velAvg = 0, acclAvg = 0, hpAvg = 0;
    int count = 0;
    
    for(creature c : swarm) {
      // Update creature traits data
      TableRow c_traitsRow = c_traits.addRow();
      c_traitsRow.setInt("   Gen   "        , generation);
      c_traitsRow.setInt("   Creature ID   ", c.num);
      c_traitsRow.setFloat("   Mass   "     , c.getMass());
      c_traitsRow.setFloat("   Width   "    , c.getWidth());
      c_traitsRow.setFloat("   Density   "  , c.getCreatureDensity());
      c_traitsRow.setFloat("   Armor   "    , c.getArmorAvg());
      //c_traitsRow.setFloat("   Wing #   ", );
      //c_traitsRow.setFloat("   Wing Size   ", );
      //c_traitsRow.setFloat("   Antennae #   ", );
      //c_traitsRow.setFloat("   Color   ", );
      c_traitsRow.setFloat("   Velocity   " , c.maxMovementForce);
      //c_traitsRow.setFloat("   Acceleration   ", );
      c_traitsRow.setFloat("   Max HP   "   , c.maxHealth); 
      
      // Update creature trait averages data
      massAvg  += c.getMass();
      widthAvg += c.getWidth();
      denseAvg += c.getCreatureDensity();
      armorAvg += c.getArmorAvg();
      velAvg   += c.maxMovementForce;
      hpAvg    += c.maxHealth;
      
      // Update creature reproduction data
      TableRow repRow = reproduction.addRow();
      repRow.setInt("   Gen   "          , generation);
      repRow.setInt("   Creature ID   "  , c.num);
      repRow.setInt("   Spawn X   "      , (int)c.sPos.x / cellWidth);
      repRow.setInt("   Spawn Y   "      , (int)c.sPos.y / cellHeight);
      repRow.setInt("   # of Gametes   " , c.gameteStack.size());
      repRow.setFloat("   Gamete Cost   ", c.baseGameteCost + c.genome.avg(gameteCost));
      repRow.setFloat("   Gamete Time   ", c.baseGameteTime + c.genome.avg(gameteTime));
      repRow.setString("   Inheritance Chromo 1   ", c.genome.xChromosome.inherit);   
      repRow.setString("   Inheritance Chromo 2   ", c.genome.yChromosome.inherit);  
      
      // Update the creature senses data
      TableRow senseRow = sensing.addRow();
      senseRow.setInt("   Gen   "           , generation);
      senseRow.setInt("   Creature ID   "   , c.num);
      senseRow.setInt("   Creature Scent   ", c.getScentType());
      //senseRow.setInt("   Creature Taste   ", );
      
      // Update the creature metabolism data
      TableRow metabRow = metabolism.addRow();
      metabRow.setInt("   Gen   "                    , generation);
      metabRow.setInt("   Creature ID   "            , c.num);
      metabRow.setFloat("   Total Energy Space   "   , c.total_energy_space);
      metabRow.setFloat("   Total Energy Consumed   ", c.total_energy_consumed);
      metabRow.setFloat("   Locomotion Space   "     , c.max_energy_locomotion);
      metabRow.setFloat("   Locomotion Used   "      , c.locomotion_used);
      metabRow.setFloat("   Reproduction Space   "   , c.max_energy_reproduction);
      metabRow.setFloat("   Reproduction Used   "    , c.reproduction_used);
      metabRow.setFloat("   Reproduction Passed   "  , c.reproduction_passed);
      metabRow.setFloat("   Health Space   "         , c.max_energy_health);
      metabRow.setFloat("   Health Used   "          , c.health_used);
      metabRow.setFloat("   Total Energy Used   "    , c.locomotion_used + c.reproduction_used + c. health_used);
      
      // Update the creature lifetime ticks data
      TableRow ticksRow = lifetime.addRow();
      ticksRow.setInt("   Gen   "           , generation);
      ticksRow.setInt("   Creature ID   "   , c.num);
      ticksRow.setInt("   Ticks on Algae   ", c.time_on_land);
      ticksRow.setInt("   Ticks on Water   ", c.time_in_water);
      //ticksRow.setInt("   Ticks on Rock   " , );
      ticksRow.setInt("   Total Lifetime   ", c.timestep_counter);
      
      // Update the player impact data
      String status;
      if(c.alive) status = "Survived";  else status = "Died";
      TableRow impactRow = p_impact.addRow();
      impactRow.setInt("   Gen   "                  , generation);
      impactRow.setInt("   Creature ID   "          , c.num);
      impactRow.setString("   Died/Survived   "     , status);
      impactRow.setInt("   Times Hit by Tower   "   , c.hits_by_tower);
      impactRow.setFloat("   HP Removed by Tower   ", c.hp_removed_by_tower);
      impactRow.setFloat("   Final HP   "           , c.health);
      
      count ++;
    }
    
    // Update creature trait averages data
    TableRow c_avgsRow = c_avgs.addRow();
    c_avgsRow.setInt("   Gen   ", generation);
    c_avgsRow.setFloat("   Avg Mass   ", massAvg/count);
    c_avgsRow.setFloat("   Avg Width   ", widthAvg/count);
    c_avgsRow.setFloat("   Avg Density   ", denseAvg/count);
    c_avgsRow.setFloat("   Avg Armor   ", armorAvg/count);
    c_avgsRow.setFloat("   Avg Wing #   ", wingAvg/count);
    c_avgsRow.setFloat("   Avg Wing Size   ", wingSizeAvg/count);
    c_avgsRow.setFloat("   Avg Antennae #   ", antennaeAvg/count);
    c_avgsRow.setFloat("   Avg Color   ", colorAvg/count);
    c_avgsRow.setFloat("   Avg Velocity   ", velAvg/count);
    c_avgsRow.setFloat("   Avg Acceleration   ", acclAvg/count);
    c_avgsRow.setFloat("   Avg Max HP   ", hpAvg/count);
    
  //TODO: Create loop thru for all towers
      // Update the player stats data
      TableRow pstatsRow = p_stats.addRow();
      pstatsRow.setInt("   Gen   "                         , generation);
      //pstatsRow.setInt("   Tower ID   "                    , );
      //pstatsRow.setInt("   Round # of Shots   "            , );
      //pstatsRow.setInt("   Total # of Shots   "            , );
      //pstatsRow.setInt("   Round Successful Hits   "       , );
      //pstatsRow.setInt("   Total Successful Hits   "       , );
      //pstatsRow.setInt("   Round Rock Hits   "             , );
      //pstatsRow.setInt("   Total Rock Hits   "             , );
      //pstatsRow.setFloat("   Round Accuracy   "            , );
      //pstatsRow.setFloat("   Overall Accuracy   "          , );
      //pstatsRow.setFloat("   Round Avg RoF   "             , );
      //pstatsRow.setFloat("   Overall Avg RoF   "           , );
      //pstatsRow.setInt("   Round # of Kills   "            , );
      //pstatsRow.setInt("   Total # of Kills   "            , );
      //pstatsRow.setFloat("   Round Avg Shots per Kill   "  , );
      //pstatsRow.setFloat("   Overall Avg Shots per Kill   ", );
      
    // Update the environment data
    fConsumed += (fStart - foods.size());
    tStrikes += rStrikes;
    tKills += rKills;
    TableRow envRow = env.addRow();
    envRow.setInt("   Gen   "                       , generation);
    envRow.setInt("   Food at Start   "             , fStart);
    envRow.setInt("   Food at End   "               , foods.size());
    envRow.setInt("   Food Consumed   "             , fStart - foods.size());
    envRow.setInt("   Total Food   "                , fTotal);
    envRow.setInt("   Total Consumed   "            , fConsumed);
    envRow.setInt("   Round Lightning Strikes   "   , (int)rStrikes);
    envRow.setInt("   Round Lightning Kills   "     , (int)rKills);
    envRow.setFloat("   Round Lightning Accuracy   ",  rKills / rStrikes);
    envRow.setInt("   Total Lightning Strikes   "   , (int)tStrikes);
    envRow.setInt("   Total Lightning Kills   "     , (int)tKills);
    envRow.setFloat("   Overall Lightning Accuracy   ", tKills / tStrikes);
    //reset environment round variables.
    rStrikes = 0;
    rKills = 0;
    
    writeTables(); 
  }
}
