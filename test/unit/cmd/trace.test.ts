import * as sinon from 'sinon';
import {expect} from 'chai';
import {Socket} from 'socket.io-client';
import {getCmdMock, getCmdMockResult} from '../../utils.js';
import {TracerouteCommand} from '../../../src/command/traceroute-command.js';

describe('trace command', () => {
	const sandbox = sinon.createSandbox();
	const mockSocket = sandbox.createStubInstance(Socket);

	beforeEach(() => {
		sandbox.reset();
	});

	describe('mock', () => {
		const testCases = ['trace-success-linux', 'trace-private-ip-linux'];

		for (const testCase of testCases) {
			it(`should run and parse trace - ${testCase}`, async () => {
				const options = {
					target: 'google.com',
					port: 53,
					protocol: 'UDP',
				};

				const rawOutput = getCmdMock(testCase);
				const expectedResult = getCmdMockResult(testCase);

				const mockCmd = Promise.resolve({stdout: rawOutput});

				const ping = new TracerouteCommand((): any => mockCmd);
				await ping.run(mockSocket as any, 'measurement', 'test', options);

				expect(mockSocket.emit.calledOnce).to.be.true;
				expect(mockSocket.emit.firstCall.args[0]).to.equal('probe:measurement:result');
				expect(mockSocket.emit.firstCall.args[1]).to.deep.equal(expectedResult);
			});
		}
	});
});
