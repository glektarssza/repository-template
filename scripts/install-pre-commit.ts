import yargs, {
    type Argv,
    type CommandModule,
    type Options,
    type ParserConfigurationOptions
} from 'yargs';

type SyncFailCallback<T = unknown, E extends Error = Error, R = void> = (
    msg: string,
    err: E,
    yargsInstance: Argv<T>
) => R;
type PromiseFailCallback<T = unknown, E extends Error = Error, R = void> = (
    msg: string,
    err: E,
    yargsInstance: Argv<T>
) => Promise<R>;
type FailCallback<T = unknown, E extends Error = Error, R = void> =
    | SyncFailCallback<T, E, R>
    | PromiseFailCallback<T, E, R>;

interface GlobalOptions {
    verbose?: boolean;
    help?: boolean;
    version?: boolean;
    completionScript?: boolean;
}
interface CommandOptions extends GlobalOptions {}

let verboseEnabled = false;
const CLI_OPTIONS: Record<string, Options> = {
    verbose: {
        alias: 'v',
        boolean: true,
        default: false,
        description: 'Whether to enabled verbose logging.',
        global: true,
        group: 'Logging',
        requiresArg: false
    },
    help: {
        alias: 'h',
        boolean: true,
        default: false,
        description: 'Output the help information and exit.',
        global: true,
        group: 'Misc.',
        requiresArg: false
    },
    version: {
        boolean: true,
        default: false,
        description: 'Output the version information and exit.',
        global: true,
        group: 'Misc.',
        requiresArg: false
    },
    'completion-script': {
        boolean: true,
        default: false,
        description: 'Generate a completion script.',
        global: true,
        requiresArg: false,
        group: 'Misc.'
    }
};
const SCRIPT_NAME = 'install-pre-commit';
const SCRIPT_VERSION = 'v0.1.0';
const SCRIPT_COPYRIGHT =
    "Copyright (c) 2026 G'lek Tarssza, all rights reserved";
const ENABLE_CLI_HELP = false;
const ENABLE_CLI_VERSION = false;
const ENABLE_CLI_ENV = true;
const STRICT_CLI_OPTIONS = false;
const STRICT_CLI_COMMANDS = true;
const EXIT_PROCESS_ON_FAIL = false;
const {columns: TERMINAL_WIDTH} = Deno.consoleSize();
const YARGS_PARSER_OPTIONS: ParserConfigurationOptions = {
    'boolean-negation': true,
    'camel-case-expansion': true,
    'combine-arrays': false,
    'dot-notation': true,
    'duplicate-arguments-array': true,
    'flatten-duplicate-arrays': true,
    'greedy-arrays': false,
    'halt-at-non-option': false,
    'nargs-eats-options': false,
    'negation-prefix': 'no-',
    'parse-numbers': true,
    'parse-positional-numbers': true,
    'populate--': false,
    'set-placeholder-key': false,
    'short-option-groups': true,
    'sort-commands': true,
    'strip-aliased': true,
    'strip-dashed': false,
    'unknown-options-as-args': false
};
const utf8TextEncoder = new TextEncoder();
const writeStdoutSync = (msg: string) => {
    const buffer = utf8TextEncoder.encode(msg);
    Deno.stdout.writeSync(buffer);
};
const writeStdout = async (msg: string) => {
    const buffer = utf8TextEncoder.encode(msg);
    await Deno.stdout.write(buffer);
};
const writeLineStdoutSync = (msg: string) => {
    writeStdoutSync(`${msg}\n`);
};
const writeLineStdout = async (msg: string) => {
    await writeStdout(`${msg}\n`);
};
const logError = (...data: unknown[]) => {
    const msg = data.join(' ');
    if (Deno.noColor) {
        writeLineStdoutSync(`[ERROR] ${msg}`);
    } else {
        writeLineStdoutSync(`\x1B[38:5:196m[ERROR]\x1B[0m ${msg}`);
    }
};
// deno-lint-ignore no-unused-vars
const logWarning = (...data: unknown[]) => {
    const msg = data.join(' ');
    if (Deno.noColor) {
        writeLineStdoutSync(`[WARN] ${msg}`);
    } else {
        writeLineStdoutSync(`\x1B[38:5:208m[WARN]\x1B[0m ${msg}`);
    }
};
const logInfo = (...data: unknown[]) => {
    const msg = data.join(' ');
    if (Deno.noColor) {
        writeLineStdoutSync(`[INFO] ${msg}`);
    } else {
        writeLineStdoutSync(`\x1B[38:5:111m[INFO]\x1B[0m ${msg}`);
    }
};
const logVerbose = (...data: unknown[]) => {
    if (!verboseEnabled) {
        return;
    }
    const msg = data.join(' ');
    if (Deno.noColor) {
        writeLineStdoutSync(`[VERBOSE]\ ${msg}`);
    } else {
        writeLineStdoutSync(`\x1B[38:5:141m[VERBOSE]\x1B[0m ${msg}`);
    }
};
const COMMAND_MODULE: CommandModule<GlobalOptions, CommandOptions> = {
    command: '$0',
    builder: (yargInstance) => {
        return yargInstance;
    },
    handler: async (args) => {
        verboseEnabled = args.verbose ?? false;
        if (args.help) {
            await writeLineStdout(await parser.getHelp());
            Deno.exit(0);
        }
        if (args.version) {
            await writeLineStdout(`${SCRIPT_NAME} ${SCRIPT_VERSION}`);
            await writeLineStdout(SCRIPT_COPYRIGHT);
            Deno.exit(0);
        }
        if (args.completionScript) {
            parser.showCompletionScript();
            Deno.exit(0);
        }
        logInfo('Hello, world!');
        logVerbose('Hello, world, verbosely!');
    },
    deprecated: false,
    describe: false
};
const onFail: FailCallback = async (msg, error) => {
    logError('Fatal error while running script!');
    logError(`Error message: "${msg}"`);
    if (error?.stack) {
        logError('Stack trace:');
        await writeLineStdout(error.stack);
    } else {
        logError('No stack trace available!');
    }
};

const parser = yargs(Deno.args)
    .scriptName(SCRIPT_NAME)
    .epilog(SCRIPT_COPYRIGHT)
    .strictOptions(STRICT_CLI_OPTIONS)
    .strictCommands(STRICT_CLI_COMMANDS)
    .env(ENABLE_CLI_ENV)
    .help(ENABLE_CLI_HELP)
    .version(ENABLE_CLI_VERSION)
    .exitProcess(EXIT_PROCESS_ON_FAIL)
    .fail(onFail)
    .parserConfiguration(YARGS_PARSER_OPTIONS)
    .wrap(TERMINAL_WIDTH)
    .options(CLI_OPTIONS) as Argv<CommandOptions>;
parser
    .command(COMMAND_MODULE)
    .demandCommand(
        1,
        1,
        'A command is required!',
        'At most one command can be used!'
    )
    .parse();
