"""Reviewed September 13 SpriteFlow clips; preserve source PNG bytes and gameplay data."""
import sys
import integrate_spriteflow as pipeline

clip = pipeline.clip
CONFIG = {
    'frost_wolf': {
        'Idle': clip('frost_wolf_idle_walk_1042', 1, 8, 8),
        'Walk': clip('frost_wolf_idle_walk_1042', 9, 32, 8),
        'Attack': clip('frost_wolf_attack_hit_die_1103', 1, 7, 8, 5),
        'Hit': clip('frost_wolf_attack_hit_die_1103', 8, 10, 12),
        # Source 28-32 stands back up: never include these in a death animation.
        'Die': clip('frost_wolf_attack_hit_die_1103', 11, 27, 8),
    },
    'ice_troll': {
        'Idle': clip('ice_troll_idle_walk_1136', 1, 8, 8),
        'Walk': clip('ice_troll_idle_walk_1136', 9, 32, 8),
        'Attack': clip('ice_troll_attack_hit_die_1106', 1, 13, 8, 7),
        'Hit': clip('ice_troll_attack_hit_die_1106', 14, 20, 12),
        'Die': clip('ice_troll_attack_hit_die_1106', 21, 32, 8),
    },
    'wall_shieldbearer': {
        'Idle': clip('shield_idle_walk_1147', 1, 8, 8),
        'Walk': clip('shield_idle_walk_1147', 9, 32, 8),
        'Attack': clip('shield_attack_1450', 1, 32, 8, 7),
        'Hit': clip('shield_attack_hit_die_1151', 7, 13, 12),
        'Die': clip('shield_attack_hit_die_1151', 14, 32, 8),
    },
    'stone_hrungnir': {
        'Idle': clip('stone_hrungnir_idle_walk_1132', 1, 8, 8),
        'Walk': clip('stone_hrungnir_idle_walk_1132', 9, 32, 8),
        'Attack': clip('stone_hrungnir_attack_hit_die_1132', 1, 11, 8, 5),
        'Hit': clip('stone_hrungnir_attack_hit_die_1132', 12, 16, 12),
        'Die': clip('stone_hrungnir_attack_hit_die_1132', 17, 32, 8),
    },
}

if __name__ == '__main__':
    for monster in sys.argv[1:] or CONFIG:
        pipeline.install(monster, CONFIG[monster])
