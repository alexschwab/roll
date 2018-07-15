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
  writecln(Color.cyan, "For example: 'roll 10d8 best 4', or 'roll worst1 3d6'");
  exit(0);
}

void checkStats(in string[] args)
{
  for(int i = 0; i < args.length; ++i)
  {
    if(matchFirst(args[i], ctRegex!(r"(stat)", "i"))) // case insensitive matching
    {
      rollStats(10);
      exit(0);
    }
  }
}

void checkPercentile(in string[] args)
{
  for(int i = 0; i < args.length; ++i)
  {
    if(matchFirst(args[i], ctRegex!(r"(percentile)", "i"))) // case insensitive matching
    {
      double result = uniform01() * 100.0;
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
  
  for(int i = 0; i < args.length; ++i)
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
  foreach(cmd ; args)
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
  for(int i = 0; i < params.numDice; ++i)
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
  int[] stats = new int[](6);
  for(int i = 0; i < 6; ++i)
  {
    int[] rolls = new int[](4);
  Retry:
    for(int j = 0; j < 4; ++j)
    {
      rolls[j] = cast(int)(uniform01() * 6 + 1);
    }
    sort!("a > b")(rolls);

    for(int j = 0; j < 3; ++j)
    {
      stats[i] += rolls[j];
    }

    if(stats[i] < minStat)
    {
      stats[i] = 0;
      goto Retry;
    }

    writec(Color.yellow, "Rolled");
    write(": ");
    printRoll(rolls);

  }

  sort!("a > b")(stats);
  writec(Color.yellow, "\nStats");
  write(": ");
  printRoll(stats);
}

void printRoll(in int[] rolls, int length = 0)
{
  int len = length ? length : rolls.length;
  
  for(int i = 0; i < len;)
  {
    writec(Color.cyan, rolls[i]);
    if(++i < len)
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
