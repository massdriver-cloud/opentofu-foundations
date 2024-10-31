run "test_input_var_name_formatting" {
    command = plan
    variables {
        name = "   dave   "
    }

    assert {
        condition = local.name == "dave"
        error_message = "Name is incorrectly formatted"
    }
}

run "test_input_var_name_default" {
    command = plan
    assert {
        condition = local.name == "User"
        error_message = "Name is not defaulted"
    }
}

run "test_multiple_random_pets" {
    command = plan
    variables {
        names = ["curly", "larry", "mo"]
    }
    assert {
        condition = length(random_pet.multiple) == 3
        error_message = "didn't create multiple pets"
    }
}

run "test_no_pets" {
    command = plan
    assert {
        condition = random_pet.multiple == []
        error_message = "it created random pets when we it shouldnt have"
    }
}

run "test_pet_name_prefix" {
    command = apply
    variables  {
        names = ["curly"]
    }

    assert {
        condition = startswith(random_pet.multiple[0].id, "abcd_")
        error_message = "incorrect pet name prefix"
    }
}

# override_data {
#     target = data.local_file.main
#     values = {
#         content = "test"
#     }
# }

mock_provider "local" {
    mock_data "local_file" {
        defaults = {
            content = "test"
        }
    }
}

run "test_override" {
    command = apply

    assert {
        condition = data.local_file.main.content == "test"
        error_message = "local file content invalid"
    }
}