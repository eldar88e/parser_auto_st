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

**Description:**

This parser is written to parsing Sony Playstation games, prepare
this data and saving it into MySQL tables for the MODX Revolution website.

**MODX used with next extentions:**
- miniShop2
- msaddfield
- msearch2

**To run the script, fill in the following columns in the settings table:**

- site                    (example: 'https://example.com')
- path_tr                 (example: '/tr-store/all-games/')
- path_ru                 (example: '/ru-store/all-games/')
- params                  (example: '?platforms=ps5%2Cps4&sort=most-watchlisted&minPrice=15')
- ps_game                 (example: 'https://example.com/product/ps-game')
- dd_game                 (example: 'https://example.com/product/ps-game')
- exchange_rate           (example: 5.5)
- round_price             (default: 1, preferably: 10)
- parent_ps5              (example: 12)
- parent_ps4              (example: 13)
- template_id             (example: 10)
- limit_upd_lang          (default: 0, preferably: 1000)
- user_id                 (default: 1)
- limit_export            (default: 0, preferably: 700)
- small_size              (example: '40&h=40')
- medium_size             (example: '312&h=312')
- new_touched_update_desc (true or false(default: false))
- month_since_release     (1 - 12 months(default: 6 moths))
- day_lang_all_scrap      (1 - 31 day)
- telegram_chat_id        (fill out this column to send you a report in Telegram)

**To run the script, fill in the following columns in the .env file:**

- ADAPTER
- HOST
- DATABASE
- USERNAME
- PASSWORD
- BD_TABLE_NAME_MAIN
- BD_TABLE_NAME_ADDITIONAL
- BD_TABLE_NAME_RUNS
- BD_TABLE_NAME_INTRO
- BD_TABLE_NAME_CATEGORIES
- BD_TABLE_NAME_ADDITIONAL_FILES
- BD_TABLE_NAME_SETTING
- TELEGRAM_BOT_TOKEN
- FTP_HOST
- FTP_LOGIN
- FTP_PASS

_November 2022_
