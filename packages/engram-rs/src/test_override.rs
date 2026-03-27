#[cfg(test)]
mod tests {
    use owo_colors::OwoColorize;

    #[test]
    fn test_override_disabled() {
        owo_colors::set_override(false);
        let colored = "test".red().to_string();
        assert!(!colored.contains("\x1b["), "Color codes should not be present when override is false");
    }

    #[test]
    fn test_override_enabled() {
        owo_colors::set_override(true);
        let colored = "test".red().to_string();
        assert!(colored.contains("\x1b["), "Color codes should be present when override is true");
    }
}
