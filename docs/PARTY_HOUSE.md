# Private courtyard house

Walk through the open passage at the north end of Kaveh Lane to reach Mahtab's
house. The courtyard party is a fictional scene. Its entrance screen, brick and
plaster walls, raised porch, carpets, and pool draw loosely on Iranian courtyard
houses. They are not a reconstruction of any one house or city. See
[Encyclopaedia Iranica on Kashan houses](https://www.iranicaonline.org/articles/kashan-v3-traditional-architecture/)
for the entrance, courtyard, veranda, and pool arrangements that informed it.

## Where to change it

- `scripts/party_house.gd` builds the house, guests, wine cups, movement, and
  patrol interruption. Add or move guests through `GUEST_POSITIONS`.
- `scripts/person_visual.gd` builds the shared adult body and five hair styles.
  Party guests, courtyard friends, and park characters use it.
- `scripts/localization.gd` holds every English and Persian party line. Edit
  both languages for each new line.
- `scripts/world.gd` places the house and owns the street bounds. The north
  passage and navigation bounds expand from there.

The host warns the player not to tell anyone connected to the authorities.
If an existing patrol enters the house, the guests stop celebrating. Some
hide while two are taken toward the entrance for arrest.
