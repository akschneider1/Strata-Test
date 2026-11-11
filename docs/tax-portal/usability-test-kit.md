# Usability test kit

A script for watching people use the prototype. Direct File's team tested
with 195 taxpayers before and during its first filing season, and called
that direct line to users a cornerstone of the result (see
[Lessons from IRS Direct File](direct-file-lessons.md)). Nobody has used
this prototype yet. Five sessions will tell you more than another month of
building.

## Before you start

- **Who.** Five to eight taxpayers per round, mixed by age, comfort with
  computers, and language. At least two sessions in Spanish. Separately,
  three or four people who examine returns today.
- **Not real data.** Participants act as a made-up person. Nobody types
  their own name, Social Security number, income or bank details. Say this
  at the start and stop anyone who begins to.
- **Consent.** Follow your organization's rules for research with the
  public: what is recorded, who sees it, how long it is kept, and how
  participants are paid. This kit does not replace those rules.
- **Setup.** Run the demo. Each browser gets its own fresh copy of the demo
  people, so use a private window for every session, or choose **Start the
  demo over** on the home page between sessions.

  ```bash
  bin/demo
  ```

  Taxpayer sessions: use a phone, or a narrow browser window. Examiner
  sessions: use a desktop.
- **Two people.** One talks with the participant. One takes notes and does
  not speak.

## How to run a session

Read this aloud at the start:

> We are testing a prototype, not you. Nothing you do is wrong. You will act
> as a made-up person, and nothing here is filed anywhere. Please say what
> you are thinking as you go. If something is confusing, that is exactly
> what we need to know. I may not answer questions as we go, because I want
> to see what you would do on your own.

Rules for the person running it:

- Do not explain the screen. Ask "What would you do here?"
- When someone is stuck, wait. Count to ten before helping, and note that
  you helped.
- Ask "What did you expect to happen?" after anything surprising.
- Never defend the design.

## Taxpayer session (45 to 60 minutes)

### Warm up (5 minutes)

- How did you file your Colorado taxes last time? Who helped?
- What was the hardest part?

### Task 1: File a return (25 minutes)

Sign in as **Maya Torres**. Hand the participant a card with:

> You are Maya Torres, born March 14, 1996. Your Social Security number for
> today is 000-00-1001. You live at 1375 Sherman St, Denver, CO 80261. You
> lived in Colorado all year. You are not married and have no children. You
> had one job, at Front Range Outfitters. You had no other income. You want
> your refund sent to your checking account: routing number 102000021,
> account number 000123456789.

Say: "Please file Maya's Colorado tax return."

Watch for:

| Moment | What to notice |
| --- | --- |
| The checklist | Do they understand they can stop and come back? Do they know what to do first? |
| The marital status question | Do they look for "filing status"? Do they understand why they are asked this instead? |
| The income page | Do they notice the W-2 was filled in for them? Do they trust it? Do they check it against anything? Do they understand "confirm"? |
| The estimate | Do they see it? Do they believe it? |
| "How we calculated this" | Do they open it? Can they say in their own words why the refund is what it is? |
| The totals at the top of that page | Do the three figures under the refund (tax, credits, tax already paid) explain it, or do they scroll for more? |
| Bank details | Any hesitation about typing them? |
| Review and sign | Do they read it or scroll past? Do they understand what typing their name means? |
| The status page | Do they know the return was accepted? Do they know when the money arrives? |

### Task 2: Answer a question from the Department (10 minutes)

Before the session, sign in as the examiner (**Priya Shah**), pick up the
next return, and send a question as in part 3, step 3 of the
[demo guide](demo-guide.md). Sign out.

Sign in as **Jordan Lee**. Say: "You filed your return last week. See if
anything has happened."

Watch for:

- Do they find the question without help?
- Do they understand what is being asked, and why?
- Do they feel accused? Ask: "How did that message make you feel?"
- Do they know what happens after they answer?

### Spanish sessions

Run the same tasks after choosing **Español**. Also note:

- Any word or sentence the participant rereads, laughs at, or translates
  back to English.
- Whether they switch to English at any point, and where.

### Wrap up (5 minutes)

- What was the hardest part?
- Was there anything you did not trust?
- How does this compare with how you filed last time?
- Would you use this? What would stop you?

## Examiner session (45 minutes)

Load fresh data. Sign in as **Priya Shah**.

### Warm up (5 minutes)

- Walk me through the last return you reviewed. What did you look at first?
- Which systems did you have open?

### Task: Work a flagged return (30 minutes)

Say: "A return is waiting for review. Please work it the way you would at
your desk."

Watch for:

| Moment | What to notice |
| --- | --- |
| The dashboard | Do they know what needs doing? What is missing that they would look for first? |
| The return page | Can they say why the return was flagged, without help? |
| Reported and on-file amounts | Is the comparison the one they need? What else would they check, and where? |
| The "Next step" box | Do they see that asking the taxpayer and changing an amount are under "Other actions"? Is "Accept as filed" the action they expected to be offered first? |
| Asking the taxpayer | Would they write to the taxpayer at this point? In these words? |
| Changing an amount | Do they trust the recalculation? Do they want to see the arithmetic? |
| Accepting | Is anything missing before they would sign off (a second reviewer, a letter, a code)? |
| History | Is this enough for someone picking the return up later, or for an appeal? |

Then open **Service measures** and ask: "Which of these would you look at?
What is missing?"

### Wrap up (5 minutes)

- What would stop you from using this for real work?
- What does your current system do that this does not?
- Which flags would you add or remove?

## Notes template

One copy per session. Write what the person did and said, not what you
think it means.

```text
Session:            (number, date)
Participant:        (taxpayer / examiner; language; device)
Run by / notes by:

Task 1
  Finished without help?   yes / with help / no
  Time taken:
  Where they stopped or hesitated (page, what they said):
  Where we had to help (page, what we said):
  Words they did not understand:
  Anything they did not trust:

Task 2
  (same headings)

Quotes worth keeping:

What surprised us:
```

## After each round

1. The same day, both of you list every problem you saw. One line each.
2. Count how many participants hit each problem.
3. Sort by how badly it blocked people, then by how many people it hit.
4. Fix the top few, then run the next round. Change the questions and
   wording in `tax-portal/config/locales/tax/`, in English and Spanish
   together.
5. Keep the notes. A problem seen by one person in two rounds is a pattern.
