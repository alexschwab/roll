/*
file: roll.d
brief: rolls a number of dice according to input
author: Alex Schwab
Copyright 2016, all rights reserved
*/

import std.stdio, terminal;
import std.regex : matchFirst, ctRegex;
import std.conv; // to!
import std.random : uniform01;
import core.stdc.stdlib : exit;
import std.algorithm : sort, sum;

void printHelp()
{
  writeln("\nroll -- help\n");
  writeln("Expected arguments - roll [numberOfDice] d [sides of dice] <-/+> [constant]");
  writecln(Color.cyan, "For example: 'roll 4d6+2', 'roll d 20 - 1', or 'roll 3d8'\n");
  writeln("This program can also highlight the best or worst 'X' dice, with the");
  writeln("optional flags 'best X' or 'worst X'.");
  writecln(Color.cyan, "For example: 'roll 10d8 best 4', or 'roll worst1 3d6'\n");
  writeln("You can also request to roll stats for a new character. It uses the");
  writeln("roll 4d6 & take highest 3 method to generate the stats. Specify the");
  writeln("minimum stat by putting a number afterwords. By default, the min is 10.");
  writecln(Color.cyan, "For example: 'roll stat', or 'roll stats 8'\n");
  writeln("You can also request to roll percentile dice (2d10, result is 1-100)");
  writecln(Color.cyan, "For example: 'roll percentile'\n");

  exit(0);
}

// check for if the user wants to roll for stats
void checkStats(in string[] args)
{
  foreach(i, element; args)
  {
    if(matchFirst(element, ctRegex!(r"(stats?)", "i"))) // case insensitive matching
    {
      int minStat = 10;
      if ((i + 1) < args.length)
      {
        try
        {
          minStat = to!int(args[i + 1]);
          if (minStat > 18)
          {
            writeln("The maximum value of 3d6 is 18, if you set a number this high then... why are you even rolling?");
            minStat = 18;
          }
        }
        catch (ConvException)
        {
          minStat = 10;
          writeln("Error converting the argument after ", element, " to a number to specify the minimum value.");
          writeln("  Found: ", args[i + 1]);
          writeln("  Continuing anyway, using ", minStat, " as the minimum stat.");
        }
      }

      rollStats(minStat);
      exit(0);
    }
  }
}

// check if the user wants percentile dice, & rolls 1-100
void checkPercentile(in string[] args)
{
  foreach(element; args)
  {
    if(matchFirst(element, ctRegex!(r"(percentile)", "i"))) // case insensitive matching
    {
      const double result = uniform01() * 100.0;
      writec(Color.yellow, "Percentile");
      writeln(": ");
      writec(Color.cyan, cast(int)(result));
      exit(0);
    }
  }
}

void checkBestWorst(ref string[] args, ref RollArgs params)
{
  auto reg = ctRegex!(r"(?:(best)|(worst))([1-9]+\d*)?", "i"); // case insensitive matching

  for(int i; i < args.length; ++i)
  {
    auto match = matchFirst(args[i], reg); // search if user wants best or worst
    if(match.empty) // this arg didn't have best/worst
      continue;
    else
    {
      // verify argument has a matching number
      if(match[3].length)
      {
        params.numBorW = to!int(match[3]); // save the number
        // remove best/worst from args array
        args = args[0 .. i] ~ args[i + 1 .. $];
      }
      else // number was not included in best/worst arg, eg "best4" or "worst3"
      {
        // check the next argument for a number
        if(i + 1 == args.length) // best/worst came last, next can't be a number
          printHelp();
        auto numMatch = matchFirst(args[i+1], ctRegex!(r"(\d+)")); // any amount of digits in a row
        if(numMatch.empty) // next option is not a number
          printHelp();

        params.numBorW = to!int(numMatch[1]); // save the number
        // remove best/worst & the number from args
        args = args[0 .. i] ~ args[i + 2 .. $];
      }
      //determine if user wants best or worst
      if(match[1].length)
        params.showBest = true;
      else // match[2].length
        params.showWorst = true;

      return;
    }
  } // did not find best/worst in args
}

void parseInput(ref string[] args, out RollArgs params)
{
  if(args.length < 2)
  {
    writecln(Color.red, "error - too few arguments");
    printHelp();
  }

  args = args[1 .. $]; // remove program name
  checkPercentile(args);
  checkStats(args);
  checkBestWorst(args, params);

  char[] input;
  foreach(cmd; args)
    input ~= cmd ~ " "; // put all seperated commands into one char array

  // match main dice options, eg 4 d6 +2
  auto reg = ctRegex!(r"(\d*)\s*(d)\s*([1-9]+\d*)\s*(?:([-+]?)\s*(\d+))?");
  auto match = matchFirst(input, reg);
  if(match.empty)
  {
    writecln(Color.red, "error - bad input, no dice roll found.");
    printHelp();
  }

  if(match[1].length > 0)
    params.numDice = to!int(match[1]);
  else
    params.numDice = 1;

  params.numSides = to!int(match[3]);
  if(params.showBest || params.showWorst)
  {
    if(params.numDice <= params.numBorW)
      printHelp(); // doesn't make sense to ask for best of same number dice
  }

  if(match[4].length > 0)
  {
    params.constant = to!int(match[5]);
    params.constant *= setOperation(match[4][0]); // make constant neg if sub op found
  }
}

int setOperation(char op)
{
  if(op == '-')
    return -1;
  else
    return 1;
}

void printInput(in RollArgs params) // write to console what was read in
{
  writec(Color.yellow, "Results of ", params.numDice, 'd', params.numSides);
  if(params.constant > 0)
    writec(Color.yellow, '+', params.constant);
  else if(params.constant < 0)
    writec(Color.yellow, params.constant);
  write(": ");
}

void generateRoll(in RollArgs params)
{
  int sumDice;
  int[] rolls = new int[](params.numDice);

  // do rolls & sum them
  for(int i; i < params.numDice; ++i)
  {
    rolls[i] = cast(int)(uniform01() * params.numSides + 1);
    sumDice += rolls[i];
  }
  sumDice += params.constant;

  printRoll(rolls); // print in original order

  writec(Color.yellow, "Sum of Rolls"); write(": "); writecln(Color.cyan, sumDice);

  if(params.showBest)
  {
    writec(Color.yellow, "Best ", params.numBorW);
    sort!("a > b")(rolls);
  }
  else if(params.showWorst)
  {
    writec(Color.yellow, "Worst ", params.numBorW);
    sort(rolls);
  }
  else
  {
    writec(Color.yellow, "Sorted");
    sort(rolls);
  }
  write(": ");

  printRoll(rolls, params.numBorW);
}

void rollStats(int minStat)
{
  int[6] stats;
  for(int i; i < stats.length; ++i)
  {
    int[4] rolls;

    while(true)
    {
      for(int j; j < rolls.length; ++j)
      {
        rolls[j] = cast(int)(uniform01() * 6 + 1);
      }
      sort!("a > b")(rolls[]);

      // take only best 3 for rolling stats
      for(int j; j < 3; ++j)
      {
        stats[i] += rolls[j];
      }

      if(stats[i] < minStat)
      {
        stats[i] = 0;
        continue;
      }
      break;
    }

    writec(Color.yellow, "Rolled");
    write(": ");
    printRoll(rolls);
  }

  sort!("a > b")(stats[]);
  writec(Color.yellow, "\nStats");
  write(": ");
  printRoll(stats);
}

// length is used for rolling only a subset of the total rolls, useful if rolls is sorted in some way
void printRoll(int[] rolls, int length = 0)
  in(length <= rolls.length) // these are contracts, they are runtime asserts that can be disabled with compiler flags
  in(length >= 0)
{
  const int len = length ? length : rolls.length;

  for(int i = 0; i < len; ++i)
  {
    writec(Color.cyan, rolls[i]);
    if(i + 1 < len)
      write(", ");
  }
  write('\n');
}

int main(string[] args)
{
  RollArgs params;

  parseInput(args, params);
  printInput(params);
  generateRoll(params);

  return 0;
}

struct RollArgs
{
  int  numDice;
  int  numSides;
  int  constant;
  int  numBorW; // number of best or worst dice to highlight
  bool showBest = false;  // ensure by default we do not do this
  bool showWorst = false; // ensure by default we do not do this
}
