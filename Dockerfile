FROM marcermarc/garrysmod

COPY --chown=steam addons /steam/gmod/garrysmod/addons
COPY --chown=steam maps /steam/gmod/garrysmod/maps
COPY --chown=steam gamemodes /steam/gmod/garrysmod/gamemodes
COPY --chown=steam data /steam/gmod/garrysmod/data
COPY --chown=steam server.cfg /steam/gmod/garrysmod/cfg/server.cfg

ENV GLST="0F71CE9C4029E3698FAD3994C7CC6985"

CMD ["-dev", "+gamemode", "terrortown", "-maxplayers", "12", "+map", "ttt_biocube", "+rcon", "nohacko", "+host_workshop_collection", "2258099756"]
