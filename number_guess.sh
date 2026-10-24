#!/bin/bash

# Connect to the number_guess PostgreSQL database.
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))

echo "Enter your username:"
read USERNAME

USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USERNAME'")

if [[ -z $USER_ID ]]
then
  $PSQL "INSERT INTO users(username) VALUES('$USERNAME')" > /dev/null
  USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USERNAME'")
  echo "Welcome, $USERNAME! It looks like this is your first time here."
else
  USER_INFO=$($PSQL "SELECT games_played || '|' || COALESCE(best_game::text, '') FROM users WHERE user_id=$USER_ID")
  GAMES_PLAYED=$(echo "$USER_INFO" | cut -d '|' -f 1)
  BEST_GAME=$(echo "$USER_INFO" | cut -d '|' -f 2)

  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

echo "Guess the secret number between 1 and 1000:"
read GUESS

NUMBER_OF_GUESSES=1

while [[ ! $GUESS =~ ^[0-9]+$ ]] || (( GUESS != SECRET_NUMBER ))
do
  if [[ ! $GUESS =~ ^[0-9]+$ ]]
  then
    echo "That is not an integer, guess again:"
  elif (( GUESS > SECRET_NUMBER ))
  then
    echo "It's lower than that, guess again:"
  else
    echo "It's higher than that, guess again:"
  fi

  read GUESS
  (( NUMBER_OF_GUESSES++ ))
done

echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"

$PSQL "UPDATE users SET games_played = games_played + 1 WHERE user_id=$USER_ID" > /dev/null

BEST_GAME=$($PSQL "SELECT best_game FROM users WHERE user_id=$USER_ID")

if [[ -z $BEST_GAME ]] || (( NUMBER_OF_GUESSES < BEST_GAME ))
then
  $PSQL "UPDATE users SET best_game=$NUMBER_OF_GUESSES WHERE user_id=$USER_ID" > /dev/null
fi
