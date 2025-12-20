extends GutTest
# BDD: Deterministic RNG sequences

func test_given_same_seed_when_sampling_sequence_then_values_repeat():
	# Given: A fixed seed
	RandomProvider.set_seed(99)
	var seq_one := [
		RandomProvider.randi_range(0, 1000),
		RandomProvider.randi_range(0, 1000),
		RandomProvider.randi_range(0, 1000)
	]
	
	# When: Re-seeding with the same value
	RandomProvider.set_seed(99)
	var seq_two := [
		RandomProvider.randi_range(0, 1000),
		RandomProvider.randi_range(0, 1000),
		RandomProvider.randi_range(0, 1000)
	]
	
	# Then: Sequences are identical
	assert_eq(seq_one, seq_two, "Sequences should repeat with identical seed")

func test_given_shuffle_when_seeded_then_order_is_reproducible():
	# Given: A deterministic seed
	var items := [1, 2, 3, 4, 5]
	RandomProvider.set_seed(202)
	var shuffled_one := RandomProvider.shuffle(items)
	
	# When: Re-seeded with the same value
	RandomProvider.set_seed(202)
	var shuffled_two := RandomProvider.shuffle(items)
	
	# Then: Shuffle order is stable
	assert_eq(shuffled_one, shuffled_two, "Shuffle should be reproducible with fixed seed")

func test_given_choice_when_seeded_then_selection_is_reproducible():
	# Given: Deterministic seed and candidates
	var candidates := ["A", "B", "C"]
	RandomProvider.set_seed(7)
	var first_pick := RandomProvider.choice(candidates)
	var second_pick := RandomProvider.choice(candidates)
	
	# When: Re-seeded and re-run
	RandomProvider.set_seed(7)
	var first_pick_again: Variant = RandomProvider.choice(candidates)
	var second_pick_again: Variant = RandomProvider.choice(candidates)
	
	# Then: Choices repeat identically
	assert_eq([first_pick, second_pick], [first_pick_again, second_pick_again], "Choices should repeat with fixed seed")
