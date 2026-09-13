"""Afternoon SpriteFlow additions: mammoth, stone soldier, and shieldbearer attack."""
import sys
from copy import deepcopy
from import_spriteflow_chapter4 import CONFIG as PREVIOUS, pipeline, clip

CONFIG = {
    'stone_soldier': {
        'Idle': clip('stone_soldier_idle_walk_1500', 1, 8, 8),
        'Walk': clip('stone_soldier_idle_walk_1500', 9, 32, 8),
        'Attack': clip('stone_soldier_attack_1459', 1, 32, 8, 7),
        'Hit': clip('stone_soldier_attack_hit_die_1451', 3, 10, 12),
        # The source resets to a standing pose at frame 28.
        'Die': clip('stone_soldier_attack_hit_die_1451', 11, 27, 8),
    },
    'snow_mammoth': {
        'Idle': clip('snow_mammoth_idle_walk_1518', 1, 8, 8),
        'Walk': clip('snow_mammoth_idle_walk_1518', 9, 32, 8),
        'Attack': clip('snow_mammoth_attack_1518', 1, 32, 8, 9),
        'Hit': clip('snow_mammoth_hit_die_1519', 1, 8, 12),
        'Die': clip('snow_mammoth_hit_die_1519', 9, 32, 8),
    },
    'wall_shieldbearer': deepcopy(PREVIOUS['wall_shieldbearer']),
}

if __name__ == '__main__':
    for monster in sys.argv[1:] or CONFIG:
        pipeline.install(monster, CONFIG[monster])
