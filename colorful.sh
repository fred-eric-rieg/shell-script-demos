#!/bin/bash

# Time for colorful display of CLI text


# \033[ is ANSI escape sequence
# 0 is dim style, 1 is bright style
# 31m are colors and 0m is default (white)
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
NEONGREEN='\033[1;32m'
NC='\033[0m'

echo -e "${RED}Das hier ist in Rot${NC}"
echo -e "${GREEN}Alles im grünen Bereich${NC}"
echo -e "${ORANGE}Sollte Orange sein${NC}"
echo -e "${BLUE}Blau!${NC}"
echo -e "${NEONGREEN}Neongrün${NC}"
