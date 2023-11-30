# Parser
### Parser for Sony game

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

_November 2022_

