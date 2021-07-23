#!/bin/bash

ENV_JS_FILE_PATH=$1
# Recreate env file
rm "$ENV_JS_FILE_PATH"
touch "$ENV_JS_FILE_PATH"

# Add assignment
echo "window.env = {" >> "$ENV_JS_FILE_PATH"

# Read each line in .env file
# Each line represents key=value pairs
while read -r line || [[ -n "$line" ]];
do
  # Skip all env vars which doesn't start with REACT_APP_
  if [[ $line != REACT_APP_* ]]; then
    continue
  fi

  # Split env variables by character `=`
  if printf '%s\n' "$line" | grep -q -e '='; then
    varname=$(printf '%s\n' "$line" | sed -e 's/=.*//')
    varvalue=$(printf '%s\n' "$line" | sed -e 's/^[^=]*=//')
  fi

  # Read value of current variable if exists as Environment variable
  value=$(printf '%s\n' "${!varname}")
  # Otherwise use value from .env file
  [[ -z $value ]] && value=${varvalue}

  # Append configuration property to JS file
  echo "  $varname: \"$value\"," >> "$ENV_JS_FILE_PATH"
done < .env.template

echo "}" >> "$ENV_JS_FILE_PATH"
