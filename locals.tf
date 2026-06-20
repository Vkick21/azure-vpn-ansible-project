locals {
  # Bastion moze zostac pominiety w trybie oszczednym lub przez osobny przelacznik.
  bastion_enabled = var.enable_bastion && var.env_mode == "full"
}
