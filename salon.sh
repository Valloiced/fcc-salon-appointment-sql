#! /bin/bash

PSQL="psql -X --username=freecodecamp --dbname=salon --tuples-only -c"

echo -e "\n~~~ MY SALON ~~~\n"

echo -e "Welcome to My Salon, how can I help you?\n"

CHOOSE_SERVICE() {
  # For misinputs
  if [[ $1 ]]
  then 
    echo -e "\n$1"
  fi

  # Retrieve services that are offered
  GET_SERVICES=$(
    $PSQL "
    SELECT * 
    FROM services
  ")

  # Display services
  echo "$GET_SERVICES" | while read SERVICE_ID BAR SERVICE_NAME
  do
    echo "$SERVICE_ID) $SERVICE_NAME"
  done

  # Customer choose a service
  read SERVICE_ID_SELECTED

  # Rerun if wrong or misinput
  if [[ -z $SERVICE_ID_SELECTED || ! $SERVICE_ID_SELECTED =~ ^[0-9]+$ ]]
  then
    CHOOSE_SERVICE "Please choose from the listed services."
    return
  fi

  # Test if service exist and store the service name
  SERVICE_NAME=$(
    $PSQL "
    SELECT name 
    FROM services 
    WHERE service_id=$SERVICE_ID_SELECTED
  ")

  if [[ -z $SERVICE_NAME ]]
  then
    CHOOSE_SERVICE "I could not find that service. What would you like today?"
    return
  else
    # Reformat the service name to delete whitespaces
    SERVICE_NAME_FORMAT=$(echo "$SERVICE_NAME" | sed -E 's/^ *| *$//g')

    # Proceed to the appointment
    APPOINTMENT
  fi
}

APPOINTMENT() {
  # Get customer's phone
  echo -e "\nWhat's your phone number?"
  read CUSTOMER_PHONE

  # Check if it exists
  CUSTOMER=$(
    $PSQL "SELECT customer_id, name 
    FROM customers 
    WHERE phone='$CUSTOMER_PHONE'
  ")

  if [[ -z $CUSTOMER ]]
  then
    # Create new customer in the database if does not exist
    CREATE_NEW_CUSTOMER
  else
    # Remove Whitespace
    CUSTOMER_FORMAT=$(echo "$CUSTOMER" | sed -E 's/^ *| *$//g')
    
    # Extract data from CUSTOMER
    CUSTOMER_ID=$(echo "$CUSTOMER_FORMAT" | sed -E 's/ \|.*//g')
    CUSTOMER_NAME=$(echo "$CUSTOMER_FORMAT" | sed -E 's/.*\| //g' )
  fi

  echo -e "\nWhat time would you like your $SERVICE_NAME_FORMAT, $CUSTOMER_NAME?"
  read SERVICE_TIME

  ADD_APPOINTMENT_RESULT=$(
    $PSQL "
    INSERT INTO appointments(customer_id, service_id, time) 
    VALUES($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$SERVICE_TIME')
  ")

  # Check if there's an error
  if [[ $ADD_APPOINTMENT_RESULT == 'INSERT 0 1' ]]
  then
    echo -e "I have put you down for a $SERVICE_NAME_FORMAT at $SERVICE_TIME, $CUSTOMER_NAME."
  else 
    # Return back to main menu if failed
    CHOOSE_SERVICE "Failed to schedule your appointment"
  fi 
}

CREATE_NEW_CUSTOMER() {
  # Get customer name
  echo -e "\nI don't have a record for that phone number, what's your name?"
  read CUSTOMER_NAME

  # Create the customer
  CREATE_CUSTOMER_RESULT=$(
    $PSQL "
    INSERT INTO customers(name, phone) 
    VALUES('$CUSTOMER_NAME', '$CUSTOMER_PHONE')
  ")

  # Check if there's an error
  if [[ $CREATE_CUSTOMER_RESULT == 'INSERT 0 1' ]]
  then
    # Reassign CUSTOMER_ID, the CUSTOMER_NAME is already assign upon read
    CUSTOMER_ID=$(
      $PSQL "
      SELECT customer_id 
      FROM customers 
      WHERE phone='$CUSTOMER_PHONE' AND name='$CUSTOMER_NAME'
    ")
  else 
    # Return back to main menu if failed
    CHOOSE_SERVICE "Failed to create customer."
    return
  fi
}

# Start Service
CHOOSE_SERVICE