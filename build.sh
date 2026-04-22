#!/bin/bash
docker build -t ubuntu2404-kde-rdp --build-arg USERNAME=devuser --build-arg PASSWORD=devpass .

