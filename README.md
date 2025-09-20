# Collector
## How to use?
- Install a slack application on your workspace (after admin approval).
- oAuth permissions should include read usergroups, read users.
```bash
cp .env.sample .env
```
- Edit the .env file formed and fill the Slack User OAuth Token. (or Bot token)
- Et Voilà!
```bash
bash _data_gen_v2/updateTeamUsingSlackUserGroups.sh \
    <outputYMLFileName> \
    <usergroup1> \
    <usergroup2> (so on...)
```
- or run the pre-written scripts for dev, des and all fields.