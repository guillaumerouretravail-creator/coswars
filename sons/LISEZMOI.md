# Bruitages de Coswars

Les bruitages du dossier Dropbox « Coswars » (mise à jour du 20/10/2026, 3e version) sont déjà intégrés : 297 fichiers convertis en `.mp4` (son AAC) pour 121 événements (voir `sons.json`). Les armes restent en stéréo ; les fichiers contenant plusieurs tirs ont été découpés en variantes (`_0a`, `_0b`…) et les niveaux égalisés (tirs −18 dB RMS, rechargements et petits sons −24 dB). Les ambiances de mission sont les 5 premières minutes de chaque piste. Les alarmes de distance tournent en boucle et suivent l'ennemi ; du bouclier, on garde un cycle de 0,8 s, de l'armure un seul coup, rejoués au rythme prévu.

Pour ajouter ou remplacer un son : déposez le fichier ici et modifiez `sons.json`. Une valeur peut être un fichier, une liste de fichiers (variante tirée au hasard) ou `{"f": [...], "vol": 1.5}`.

Les armes ont des clés précises : `shot_<espèce>_<long|mid|short>_t<0|1|2>_n<1|2|3>` (t = basique, medium, expert ; n = niveau 1-3, 4-6, 7-10), puis `shot_<espèce>_<distance>`, puis `shot_<distance>`. Même principe pour `reload_`, `cool_`, `step_`, `whistle_`, `death_`. Chargeur vide (`empty`) et surchauffe (`overheat`) : un seul son commun à toutes les armes et espèces. Ambiances : `amb_op<opération>_m<mission>`. Carte Venus Ville (mode Commando) : ambiance de fond `amb_venus`, sons fixes des zones `amb_venus_<cascade|plage|pyramide|academy|solarium>` (mono, boucles à fondu enchaîné, entendus en 3D jusqu'à 50 pas du point d'émission), pas du joueur selon le sol de la zone `ground_<zone>`. Alarmes en boucle (non panoramisées) : `alarm_long`, `alarm_mid`, `alarm_short`. Bruit cyclique des ennemis : `loop_dair`, `loop_tank` ; pas des ennemis : `steps_dterre`, `steps_dcmd` ; explosion à leur mort : `killOf_dterre`, `killOf_dair`, `killOf_tank`, puis `kill` (signal de destruction). Changement de position en zone défensive : `swoosh_<espèce>`. Tirs du commandant par zone : `eshotCmd_1`, `eshotCmd_2`, `eshotCmd_3`. Thème du menu : `music_menu`.

Déposez ici les fichiers audio (`.mp3`, `.wav`, `.ogg` ou `.mp4`), puis indiquez dans `sons.json` quel fichier correspond à quel événement du jeu :

```json
{
  "shot_long": "tir-sniper.wav",
  "alert_mid": "alarme-moyenne.mp3",
  "voice_dterre": "drone-terrestre.wav"
}
```

Un événement associé à un fichier remplace le son fabriqué par le jeu. Les événements non associés gardent le son actuel. Les sons d'ennemis restent placés en 3D autour du joueur.

## Événements disponibles

| Événement | Moment |
|---|---|
| `shot_long`, `shot_mid`, `shot_short` | Tir de l'arme longue, moyenne, courte portée |
| `eshot` | Tir ennemi |
| `reload_long`, `reload_mid`, `reload_short` | Début du rechargement |
| `reloaded_long`, `reloaded_mid`, `reloaded_short` | Fin du rechargement |
| `empty` | Chargeur vide |
| `wrong` | Tir avec la mauvaise arme |
| `overheat`, `cool` | Surchauffe, arme refroidie |
| `swap` | Changement d'arme |
| `alert_long`, `alert_mid`, `alert_short` | Alarmes de zone en boucle (longue, moyenne, courte) |
| `spawn` | Apparition d'un ennemi |
| `hit`, `kill` | Ennemi touché, ennemi détruit |
| `boss` | Arrivée du commandant |
| `breach` | Un ennemi percute le joueur |
| `hurt` | Le joueur est touché |
| `shieldPulse` | Bouclier sous 80 % (répété de toutes les 3 s à toutes les 1 s) |
| `shieldBreak` | Bouclier détruit, passage à l'armure |
| `armorPulse` | Armure corporelle (répété de toutes les 2 s à toutes les 1 s) |
| `heal` | Soin utilisé |
| `whistle`, `boom` | Arme de jet lancée, explosion |
| `death`, `victory` | Mort du joueur, victoire |
| `step` | Pas du joueur (fréquence selon l'espèce) |
| `swoosh` | Changement de position |
| `wall` | Mur |
| `ui_move`, `ui_sel`, `ui_back` | Menus : déplacement, validation, retour |
| `ui_deny`, `ui_locked`, `ui_hq` | Action impossible, menu pas encore accessible, ouverture du poste de commandement |
| `hitOn_shield`, `hitOn_metal`, `hitOn_organic` | Impact sur bouclier, sur blindé ou drone, sur corps |
| `killOf_metal`, `killOf_organic` | Destruction d'un blindé ou drone, d'un ennemi |
| `hurtOn_shield`, `hurtOn_armor` | Le joueur est touché sur le bouclier, sur l'armure |
| `pickupOf_weapon`, `pickupOf_ressource` | Objet ramassé |
| `weaponGain`, `rivalNear`, `whiz` | Nouvelle arme, joueur adverse proche, sifflement de balle d'ambiance |
| `defeat` | Échec de la mission |
| `voice_dterre`, `voice_dair`, `voice_boss` | Signature sonore : drone terrestre, drone aérien, commandant |
| `voice_inf`, `voice_cav`, `voice_spec`, `voice_tank`, `voice_art` | Signatures des autres ennemis |


## Évasion (26/10)

Pénitencier Olympus : `cell_closed` et `cell_open` (rejoués toutes les 3 s près des cellules), `cellOpen` (ouverture, 3 prises), sons des zones `olymp_plateforme` et `olymp_egouts` (variantes rejouées par intervalles), `amb_olymp_vent`, `amb_olymp_ateliers`, `amb_olymp_generateur` (boucles), pas métalliques `ground_metal`. Mech de surveillance : `steps_mech`, `spawnMech` (détection), `eshotOf_mech` (tirs), `hitOn_mech` (impact), `killOf_mech` (mort, 4 prises), `mechGrenade` (grenade à tête chercheuse, pas encore utilisée).
