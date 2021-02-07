#!/bin/bash

ID=$(sed -n 's:.*<Id>\(.*\)</Id>.*:\1:p' manifest.xml)
echo Creating "$ID.xrnx"
rm -f *.xrnx
zip -vr "$ID.xrnx" *.lua manifest.xml
