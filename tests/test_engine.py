"""Tests du moteur du MVP Grand Strategy-1914."""

from __future__ import annotations

import random
import tempfile
import unittest
from pathlib import Path

from game import ai, diplomacy, economy, engine, events, military, research, scenario, storage
from game.model import GameState


class ScenarioTests(unittest.TestCase):
    def test_new_game_structure(self) -> None:
        state = scenario.new_game("germany", seed=42)
        self.assertEqual(len(state.provinces), 90)
        self.assertEqual(len(state.nations), 22)
        self.assertEqual(len([n for n in state.nations.values() if n.playable]), 7)
        self.assertGreater(len(state.armies), 30)
        self.assertTrue(state.nations["germany"].is_player)
        self.assertEqual(state.player_nation, "germany")
        for province in state.provinces.values():
            self.assertEqual(province.controller, province.owner)
            self.assertIn(province.owner, state.nations)
            self.assertTrue(province.hexes)
        for province_id, neighbours in state.adjacency.items():
            for neighbour in neighbours:
                self.assertIn(province_id, state.adjacency[neighbour])

    def test_observer_game(self) -> None:
        state = scenario.new_game(None, seed=1)
        self.assertIsNone(state.player_nation)
        view = engine.build_view(state)
        self.assertTrue(view["observer"])
        self.assertIsNone(view["own"])
        self.assertEqual(len(view["armies"]), len(state.armies))

    def test_playable_nation_validation(self) -> None:
        with self.assertRaises(ValueError):
            scenario.new_game("belgium", seed=1)
        with self.assertRaises(ValueError):
            scenario.new_game("unknown", seed=1)


class EconomyTests(unittest.TestCase):
    def test_production_and_consumption(self) -> None:
        state = scenario.new_game("germany", seed=2)
        nation = state.nations["germany"]
        production = economy.national_production(state, nation)
        consumption = economy.national_consumption(state, nation)
        self.assertGreater(production["wealth"], 0)
        self.assertGreater(consumption["food"], 0)
        before = dict(nation.stock)
        economy.process_economy(state, nation)
        self.assertNotEqual(before["wealth"], nation.stock["wealth"])
        for value in nation.stock.values():
            self.assertGreaterEqual(value, 0)

    def test_construction_and_recruitment(self) -> None:
        state = scenario.new_game("germany", seed=2)
        nation = state.nations["germany"]
        nation.stock.update({"wealth": 500, "raw": 500, "food": 500})
        province = next(p for p in state.provinces.values() if p.owner == "germany")
        ok, _ = economy.queue_construction(state, nation, province.id, "industry")
        self.assertTrue(ok)
        ok, _ = economy.queue_recruit(state, nation, province.id, "infantry", 2)
        self.assertTrue(ok)
        for _ in range(3):
            economy.process_construction(state, nation)
            economy.process_recruits(state, nation)
        self.assertFalse(nation.construction)
        self.assertFalse(nation.recruits)

    def test_development_index(self) -> None:
        state = scenario.new_game(None, seed=2)
        for nation in state.nations.values():
            index = economy.development_index(state, nation)
            self.assertGreaterEqual(index, 0.0)
            self.assertLessEqual(index, 1.0)


class MilitaryTests(unittest.TestCase):
    def test_war_required_to_enter_enemy_province(self) -> None:
        state = scenario.new_game("france", seed=3)
        army = next(a for a in state.nation_armies("france") if a.province == "france_alsace_lorraine")
        ok, _ = military.validate_move(state, army, "germany_wurtemberg")
        self.assertFalse(ok)
        diplomacy.declare_war(state, state.nations["france"], "germany")
        ok, _ = military.validate_move(state, army, "germany_wurtemberg")
        self.assertTrue(ok)

    def test_combat_captures_undefended_province(self) -> None:
        state = scenario.new_game("france", seed=3)
        diplomacy.declare_war(state, state.nations["france"], "germany")
        army = next(a for a in state.nation_armies("france") if a.province == "france_alsace_lorraine")
        army.infantry = 200
        for german in list(state.nation_armies("germany")):
            if german.province == "germany_wurtemberg":
                state.armies.pop(german.id)
        messages = military.resolve_movement(
            state,
            [{"army": army.id, "to": "germany_wurtemberg"}],
            random.Random(1),
        )
        self.assertEqual(state.provinces["germany_wurtemberg"].controller, "france")
        self.assertTrue(any(m["category"] == "occupation" for m in messages))

    def test_supply_loss_when_cut_off(self) -> None:
        state = scenario.new_game("france", seed=4)
        army = state.nation_armies("france")[0]
        army.province = "russia_moscou"
        before = army.supply
        military.update_supply(state)
        self.assertLess(army.supply, before)

    def test_fog_of_war(self) -> None:
        state = scenario.new_game("france", seed=5)
        view = engine.build_view(state, "france")
        visible_ids = {army["id"] for army in view["armies"]}
        german_ids = {army.id for army in state.nation_armies("germany")}
        self.assertTrue(german_ids - visible_ids, "une armee allemande lointaine devrait etre masquee")
        observer = engine.build_view(state, None)
        self.assertEqual(len(observer["armies"]), len(state.armies))


class DiplomacyTests(unittest.TestCase):
    def test_war_and_peace(self) -> None:
        state = scenario.new_game("germany", seed=6)
        germany = state.nations["germany"]
        ok, _ = diplomacy.declare_war(state, germany, "france")
        self.assertTrue(ok)
        self.assertIn("france", germany.wars)
        self.assertIn("germany", state.nations["france"].wars)
        ok, _ = diplomacy.make_peace(state, germany, "france")
        self.assertTrue(ok)
        self.assertNotIn("france", germany.wars)
        self.assertNotIn("germany", state.nations["france"].wars)

    def test_alliance_cascade(self) -> None:
        state = scenario.new_game("germany", seed=6)
        # La France est alliee a la Russie : une attaque allemande doit entrainer la Russie.
        diplomacy.declare_war(state, state.nations["germany"], "france")
        self.assertIn("russia", state.nations["germany"].wars)

    def test_improve_relations_costs_wealth(self) -> None:
        state = scenario.new_game("germany", seed=6)
        germany = state.nations["germany"]
        germany.stock["wealth"] = 100
        before = germany.relation("italy")
        ok, _ = diplomacy.improve_relations(state, germany, "italy")
        self.assertTrue(ok)
        self.assertGreater(germany.relation("italy"), before)
        self.assertLess(germany.stock["wealth"], 100)


class ResearchTests(unittest.TestCase):
    def test_research_completes(self) -> None:
        state = scenario.new_game("germany", seed=7)
        germany = state.nations["germany"]
        germany.techs = []
        ok, _ = research.start_research(state, germany, "army_1914_infantry")
        self.assertTrue(ok)
        germany.research_progress = 10_000
        research.process_research(state, germany)
        self.assertIn("army_1914_infantry", germany.techs)
        self.assertIsNone(germany.research_tech)

    def test_prerequisite_enforced(self) -> None:
        state = scenario.new_game("germany", seed=7)
        germany = state.nations["germany"]
        germany.techs = []
        ok, _ = research.start_research(state, germany, "army_1916_artillery")
        self.assertFalse(ok)


class EventTests(unittest.TestCase):
    def test_sarajevo_pending_and_choice(self) -> None:
        state = scenario.new_game("austria", seed=8)
        engine.end_turn(state, {})
        pending = {event["id"]: event for event in state.pending_events}
        self.assertIn("sarajevo", pending)
        before = state.nations["austria"].relation("serbia")
        engine.end_turn(state, {"event_choices": {"sarajevo": "negotiate"}})
        self.assertNotIn("sarajevo", {event["id"] for event in state.pending_events})
        self.assertTrue(state.flags.get("sarajevo_conference"))
        self.assertGreater(state.nations["austria"].relation("serbia"), before)

    def test_ai_chain_can_start_war(self) -> None:
        state = scenario.new_game(None, seed=9)
        for _ in range(4):
            engine.end_turn(state, {})
        self.assertTrue(state.fired_events)
        self.assertTrue(state.log)


class AiTests(unittest.TestCase):
    def test_ai_orders_are_legal(self) -> None:
        state = scenario.new_game(None, seed=10)
        rng = random.Random(10)
        for nation in state.nations.values():
            orders = ai.ai_orders(state, nation, rng)
            self.assertIsInstance(orders, dict)
            for move in orders["moves"]:
                army = state.armies.get(move["army"])
                self.assertIsNotNone(army)
                ok, reason = military.validate_move(state, army, move["to"])
                self.assertTrue(ok, f"{nation.id}: {reason}")

    def test_ai_long_run(self) -> None:
        state = scenario.new_game(None, seed=11)
        for _ in range(12):
            engine.end_turn(state, {})
            if state.victory:
                break
            for nation in state.nations.values():
                for value in nation.stock.values():
                    self.assertGreaterEqual(value, 0)
                for army in state.nation_armies(nation.id):
                    self.assertIn(army.province, state.provinces)
        self.assertTrue(state.victory or state.turn >= 12, "la partie doit durer au moins douze tours ou se conclure par une victoire")


class StorageTests(unittest.TestCase):
    def test_save_load_roundtrip(self) -> None:
        state = scenario.new_game("france", seed=12)
        engine.end_turn(state, {})
        with tempfile.TemporaryDirectory() as directory:
            info = storage.save_game(state, "test-save", Path(directory))
            self.assertEqual(info["name"], "test-save")
            loaded = storage.load_game("test-save", Path(directory))
            self.assertEqual(loaded.turn, state.turn)
            self.assertEqual(loaded.date_label(), state.date_label())
            self.assertEqual(loaded.player_nation, state.player_nation)
            self.assertEqual(len(loaded.armies), len(state.armies))
            self.assertEqual(
                {k: round(v, 2) for k, v in loaded.nations["france"].stock.items()},
                {k: round(v, 2) for k, v in state.nations["france"].stock.items()},
            )
            self.assertEqual(
                loaded.provinces["france_ile_de_france"].controller,
                state.provinces["france_ile_de_france"].controller,
            )


class VictoryTests(unittest.TestCase):
    def test_territorial_victory(self) -> None:
        state = scenario.new_game("germany", seed=13)
        for province in state.provinces.values():
            province.controller = "germany"
        result = engine.check_victory(state)
        self.assertIsNotNone(result)
        self.assertEqual(result["type"], "territoriale")
        self.assertEqual(result["nation"], "germany")
        self.assertTrue(result["player_won"])

    def test_no_victory_at_start(self) -> None:
        state = scenario.new_game("germany", seed=13)
        self.assertIsNone(engine.check_victory(state))

    def test_economic_victory_excludes_microstates(self) -> None:
        state = scenario.new_game(None, seed=11)
        micro = state.nations["norway"]
        self.assertGreater(economy.development_index(state, micro), 0.6)
        _, ranking = engine.economic_ranking(state, list(state.nations.values()))
        self.assertNotIn(micro.id, [nation.id for nation in ranking])
        state.economic_leader_streak[micro.id] = 99
        result = engine.check_victory(state)
        self.assertFalse(result and result.get("nation") == micro.id)
        self.assertEqual(state.economic_leader_streak.get(micro.id), 0)

    def test_economic_victory_requires_dominance(self) -> None:
        state = scenario.new_game("france", seed=13)
        config = scenario.load_config()["victory"]
        state.economic_leader_streak["france"] = config["economic_turns"] - 1
        # La France est certes la premiere puissance viable, mais son avance
        # initiale sur l'Empire ottoman reste sous le seuil de dominance.
        self.assertIsNone(engine.check_victory(state))


if __name__ == "__main__":
    unittest.main()
