import smtplib
from email.mime.text import MIMEText
import argparse
import json

def send_email(emails, repo, commit, results_path):
    msg = MIMEText(f"""
    Security Scan Report - {repo}
    Commit: {commit}
    Results: {json.dumps(results_path, indent=2)}
    """)
    
    msg['Subject'] = f'[GitHub] Security Alert - {repo}'
    msg['From'] = 'github-actions@yourdomain.com'
    msg['To'] = emails

    with smtplib.SMTP('smtp.gmail.com', 587) as server:
        server.starttls()
        server.login(os.getenv('SMTP_USER'), os.getenv('SMTP_PASSWORD'))
        server.send_message(msg)

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('--emails', required=True)
    parser.add_argument('--repo', required=True)
    parser.add_argument('--commit', required=True)
    parser.add_argument('--results', required=True)
    args = parser.parse_args()
    
    send_email(args.emails, args.repo, args.commit, args.results)
