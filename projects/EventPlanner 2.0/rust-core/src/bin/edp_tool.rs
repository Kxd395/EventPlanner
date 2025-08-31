use std::env;
use std::fs;
use eventdesk_core::{csvops, db, analytics};

fn usage() {
    eprintln!("edp_tool commands:\n  preview <csvfile>\n  commit <eventId> <csvfile> --db <dbpath>\n  export <eventId> --db <dbpath>\n  export-json <eventId> --db <dbpath>\n  counts <eventId> --db <dbpath>\n  update-status <attendanceId> <newStatus> [--db <dbpath>] [--in-progress] [--override] [--reason <txt>] [--changed-by <id>]\n  bulk-update <eventId> <attendeeIdsCsv> <newStatus> [--db <dbpath>] [--in-progress] [--override] [--reason <txt>] [--changed-by <id>]\n  list <eventId> --db <dbpath>\n  remove-attendance <attendanceId> [--db <dbpath>] [--reason <txt>] [--changed-by <id>]\n  search-members <query> [--db <dbpath>] [--limit <n>]\n  walkin --event <id> --name <name> [--email <e>] [--phone <p>] [--company <c>] [--checkin] [--db <dbpath>] [--changed-by <id>]\n  merge-members <primaryId> <duplicateId> [--db <dbpath>]\n  event-create --name <n> --starts <ts> --ends <ts> [--location <loc>] [--capacity <n>] [--status <s>] [--tz <tz>] [--desc <d>] [--db <dbpath>]\n  events [--db <dbpath>] [--limit <n>] [--offset <n>]\n  event-update --id <id> [--name <n>] [--starts <ts>] [--ends <ts>] [--location <loc>] [--capacity <n>] [--status <s>] [--tz <tz>] [--desc <d>] [--db <dbpath>]\n  rollover --event <id> --end <epoch_s> --grace <seconds> [--now <epoch_s>] [--db <dbpath>]\n  audit [--event <id>] [--attendance <id>] [--limit <n>] [--db <dbpath>]\n  member-profile <memberId> [--db <dbpath>]\n  version\n  validate-analytics <jsonfile>\n  emit-analytics <jsonfile> --out <jsonl_path>");
}

fn main() {
    let args: Vec<String> = env::args().collect();
    if args.len() < 2 { usage(); return; }
    match args[1].as_str() {
        "preview" => {
            if args.len() < 3 { usage(); return; }
            let path = &args[2];
            let text = fs::read_to_string(path).expect("read csv");
            match csvops::preview_csv_text(&text) {
                Ok(p) => println!("{}", serde_json::to_string_pretty(&p).unwrap()),
                Err(e) => { eprintln!("error: {}", e); std::process::exit(1); }
            }
        }
        "commit" => {
            if args.len() < 5 { usage(); return; }
            let event_id = &args[2];
            let csv_path = &args[3];
            let mut dbpath: Option<String> = None;
            let mut i = 4;
            while i < args.len() {
                if args[i] == "--db" && i+1 < args.len() { dbpath = Some(args[i+1].clone()); i+=2; } else { i+=1; }
            }
            let dbp = dbpath.unwrap_or_else(|| ":memory:".to_string());
            db::set_db_path(&dbp);
            let text = fs::read_to_string(csv_path).expect("read csv");
            match db::commit_csv_for_event(event_id, &text) {
                Ok(o) => println!("{}", serde_json::to_string_pretty(&o).unwrap()),
                Err(e) => { eprintln!("error: {}", e); std::process::exit(1); }
            }
        }
        "export" => {
            if args.len() < 3 { usage(); return; }
            let event_id = &args[2];
            let mut dbpath: Option<String> = None;
            let mut i = 3;
            while i < args.len() { if args[i] == "--db" && i+1 < args.len() { dbpath = Some(args[i+1].clone()); i+=2; } else { i+=1; } }
            let dbp = dbpath.unwrap_or_else(|| ":memory:".to_string());
            db::set_db_path(&dbp);
            match db::export_csv_for_event(event_id) {
                Ok(csv) => print!("{}", csv),
                Err(e) => { eprintln!("error: {}", e); std::process::exit(1); }
            }
        }
        "counts" => {
            if args.len() < 3 { usage(); return; }
            let event_id = &args[2];
            let mut dbpath: Option<String> = None;
            let mut i = 3;
            while i < args.len() { if args[i] == "--db" && i+1 < args.len() { dbpath = Some(args[i+1].clone()); i+=2; } else { i+=1; } }
            let dbp = dbpath.unwrap_or_else(|| ":memory:".to_string());
            db::set_db_path(&dbp);
            match db::counts_by_status(event_id) {
                Ok(c) => println!("{}", serde_json::to_string_pretty(&c).unwrap()),
                Err(e) => { eprintln!("error: {}", e); std::process::exit(1); }
            }
        }
        "update-status" => {
            if args.len() < 4 { usage(); return; }
            let attendance_id = &args[2];
            let new_status = &args[3];
            let mut dbpath: Option<String> = None; let mut in_progress = false; let mut override_m = false; let mut reason: Option<String> = None; let mut changed_by: Option<String> = None;
            let mut i = 4;
            while i < args.len() {
                match args[i].as_str() {
                    "--db" if i+1 < args.len() => { dbpath = Some(args[i+1].clone()); i+=2; },
                    "--in-progress" => { in_progress = true; i+=1; },
                    "--override" => { override_m = true; i+=1; },
                    "--reason" if i+1 < args.len() => { reason = Some(args[i+1].clone()); i+=2; },
                    "--changed-by" if i+1 < args.len() => { changed_by = Some(args[i+1].clone()); i+=2; },
                    _ => { i+=1; }
                }
            }
            let dbp = dbpath.unwrap_or_else(|| ":memory:".to_string());
            db::set_db_path(&dbp);
            match db::update_status(attendance_id, new_status, in_progress, override_m, reason.as_deref(), changed_by.as_deref()) {
                Ok(true) => println!("ok"),
                Ok(false) => { eprintln!("update failed"); std::process::exit(1); },
                Err(e) => { eprintln!("error: {}", e); std::process::exit(1); }
            }
        }
        "list" => {
            if args.len() < 3 { usage(); return; }
            let event_id = &args[2];
            let mut dbpath: Option<String> = None; let mut i = 3;
            while i < args.len() { if args[i] == "--db" && i+1 < args.len() { dbpath = Some(args[i+1].clone()); i+=2; } else { i+=1; } }
            db::set_db_path(&dbpath.unwrap_or_else(|| ":memory:".to_string()));
            match db::list_attendance(event_id) { Ok(rows) => println!("{}", serde_json::to_string_pretty(&rows).unwrap()), Err(e) => { eprintln!("error: {}", e); std::process::exit(1); } }
        }
        "remove-attendance" => {
            if args.len() < 3 { usage(); return; }
            let att_id = &args[2];
            let mut dbpath: Option<String> = None; let mut reason: Option<String> = None; let mut changed_by: Option<String> = None; let mut i = 3;
            while i < args.len() {
                match args[i].as_str() { "--db" if i+1 < args.len() => { dbpath = Some(args[i+1].clone()); i+=2; }, "--reason" if i+1 < args.len() => { reason = Some(args[i+1].clone()); i+=2; }, "--changed-by" if i+1 < args.len() => { changed_by = Some(args[i+1].clone()); i+=2; }, _ => { i+=1; } }
            }
            db::set_db_path(&dbpath.unwrap_or_else(|| ":memory:".to_string()));
            match db::remove_attendance(att_id, reason.as_deref(), changed_by.as_deref()) { Ok(true) => println!("ok"), _ => { eprintln!("failed"); std::process::exit(1); } }
        }
        "search-members" => {
            if args.len() < 3 { usage(); return; }
            let q = &args[2];
            let mut dbpath: Option<String> = None; let mut limit: i64 = 20; let mut i = 3;
            while i < args.len() { match args[i].as_str() { "--db" if i+1 < args.len() => { dbpath = Some(args[i+1].clone()); i+=2; }, "--limit" if i+1 < args.len() => { limit = args[i+1].parse().unwrap_or(20); i+=2; }, _ => { i+=1; } } }
            db::set_db_path(&dbpath.unwrap_or_else(|| ":memory:".to_string()));
            match db::search_members(q, limit) { Ok(rows) => println!("{}", serde_json::to_string_pretty(&rows).unwrap()), Err(e) => { eprintln!("error: {}", e); std::process::exit(1); } }
        }
        "walkin" => {
            let mut event_id: Option<String> = None; let mut name: Option<String> = None; let mut email: Option<String> = None; let mut phone: Option<String> = None; let mut company: Option<String> = None; let mut checkin = false; let mut changed_by: Option<String> = None; let mut dbpath: Option<String> = None;
            let mut i = 2;
            while i < args.len() {
                match args[i].as_str() {
                    "--event" if i+1 < args.len() => { event_id = Some(args[i+1].clone()); i+=2; },
                    "--name" if i+1 < args.len() => { name = Some(args[i+1].clone()); i+=2; },
                    "--email" if i+1 < args.len() => { email = Some(args[i+1].clone()); i+=2; },
                    "--phone" if i+1 < args.len() => { phone = Some(args[i+1].clone()); i+=2; },
                    "--company" if i+1 < args.len() => { company = Some(args[i+1].clone()); i+=2; },
                    "--checkin" => { checkin = true; i+=1; },
                    "--changed-by" if i+1 < args.len() => { changed_by = Some(args[i+1].clone()); i+=2; },
                    "--db" if i+1 < args.len() => { dbpath = Some(args[i+1].clone()); i+=2; },
                    _ => { i+=1; }
                }
            }
            let eid = event_id.expect("--event required"); let nm = name.expect("--name required");
            db::set_db_path(&dbpath.unwrap_or_else(|| ":memory:".to_string()));
            match db::create_walkin(&eid, &nm, email.as_deref(), phone.as_deref(), company.as_deref(), checkin, changed_by.as_deref()) { Ok(res) => println!("{}", serde_json::to_string_pretty(&res).unwrap()), Err(e) => { eprintln!("error: {}", e); std::process::exit(1); } }
        }
        "merge-members" => {
            if args.len() < 4 { usage(); return; }
            let primary = &args[2]; let dup = &args[3];
            let mut dbpath: Option<String> = None; let mut i = 4;
            while i < args.len() { if args[i] == "--db" && i+1 < args.len() { dbpath = Some(args[i+1].clone()); i+=2; } else { i+=1; } }
            db::set_db_path(&dbpath.unwrap_or_else(|| ":memory:".to_string()));
            match db::merge_members(primary, dup) { Ok(n) => println!("moved:{}", n), Err(e) => { eprintln!("error: {}", e); std::process::exit(1); } }
        }
        "validate-analytics" => {
            if args.len() < 3 { usage(); return; }
            let text = fs::read_to_string(&args[2]).expect("read json");
            if analytics::validate_event_json(&text) { println!("valid"); } else { println!("invalid"); std::process::exit(1); }
        }
        "emit-analytics" => {
            if args.len() < 5 { usage(); return; }
            let json_path = &args[2];
            let mut out: Option<String> = None;
            let mut i = 3;
            while i < args.len() {
                if args[i] == "--out" && i+1 < args.len() { out = Some(args[i+1].clone()); i+=2; } else { i+=1; }
            }
            let outp = out.expect("--out required");
            let txt = fs::read_to_string(json_path).expect("read json");
            if !analytics::validate_event_json(&txt) { eprintln!("invalid analytics json"); std::process::exit(1); }
            // append to file
            let mut f = fs::OpenOptions::new().create(true).append(true).open(outp).expect("open out");
            use std::io::Write;
            f.write_all(txt.as_bytes()).unwrap();
            f.write_all(b"\n").unwrap();
            println!("emitted");
        }
        _ => usage(),
    }
}
