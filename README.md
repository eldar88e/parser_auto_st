# Parser
### Parser for Sony games

**Owner**: Eldar Eminov

**Dataset**:

sony_games
sony_game_additionals
sony_game_categories
sony_game_runs

**Run commands**:

bundle exec ruby hamster.rb --grab=0001 --download for downloading games list pages

bundle exec ruby hamster.rb --grab=0001 --store for parsing main info from downloaded games list pages

bundle exec ruby hamster.rb --grab=0001 --store --lang for parsing language, date realise, genre, publisher the game

bundle exec ruby hamster.rb --grab=0001 --store --desc  for parsing description the game

**Description**:

This parser is written to parsing Sony Playstation games, prepare
this data and saving it into MySQL tables for the MODX Revolution website.

_November 2022_

