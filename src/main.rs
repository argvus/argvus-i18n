use argvus_i18n::{
    I18n, SYSTEM_CATALOG_DIR, detect_locale_from, discover_locales, validate_catalogs,
};
use std::env;

fn main() {
    let mut args = env::args().skip(1);
    let root = env::var_os("ARGVUS_I18N_DIR")
        .map(std::path::PathBuf::from)
        .unwrap_or_else(|| SYSTEM_CATALOG_DIR.into());
    match args.next().as_deref() {
        Some("get") => {
            let domain = args.next().unwrap_or_default();
            let key = args.next().unwrap_or_default();
            let values = args.collect::<Vec<_>>();
            let pairs = values.iter().filter_map(|value| value.split_once('='));
            match I18n::from_root(&root, &domain) {
                Ok(i18n) => println!("{}", i18n.tr_args(&key, pairs)),
                Err(error) => {
                    eprintln!("argvus-i18n: {error}");
                    std::process::exit(1);
                }
            }
        }
        Some("locale") => println!("{}", detect_locale_from(&root)),
        Some("list") => {
            for locale in discover_locales(&root) {
                println!("{}\t{}\t{}", locale.locale, locale.name, locale.native_name);
            }
        }
        Some("validate") => match validate_catalogs(&root, args.next().as_deref()) {
            Ok(()) => println!("catalogs valid"),
            Err(errors) => {
                for error in errors {
                    eprintln!("{error}");
                }
                std::process::exit(1);
            }
        },
        _ => {
            eprintln!(
                "usage: argvus-i18n <get DOMAIN KEY [name=value ...]|locale|list|validate [LOCALE]>"
            );
            std::process::exit(2);
        }
    }
}
