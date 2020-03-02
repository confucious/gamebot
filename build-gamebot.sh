#!/bin/sh

make quick_deploy_lambda \
   SWIFT_EXECUTABLE=Gamebot \
   SWIFT_PROJECT_PATH=gamebot \
   LAMBDA_FUNCTION_NAME=Gamebot \
   LAMBDA_HANDLER=Gamebot.gamebot
